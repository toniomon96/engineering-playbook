[CmdletBinding()]
param(
  [string]$PortfolioRoot,
  [string[]]$HealthUrl,
  [switch]$StatusOnly
)

$ErrorActionPreference = "Stop"

$playbookRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if (-not $PortfolioRoot) {
  $PortfolioRoot = Split-Path -Parent $playbookRoot
}

$repos = @(
  "consulting",
  "engineering-playbook",
  "hub",
  "hub-prompts",
  "hub-registry",
  "FamilyTrips",
  "demario-pickleball-1",
  "dse-content"
)

$requiredManifestFields = @(
  "repo_id",
  "display_name",
  "repo_type",
  "owner",
  "client_id",
  "engagement_id",
  "sensitivity_tier",
  "domains",
  "allowed_context_consumers",
  "artifact_roots",
  "source_of_truth_files",
  "status",
  "created_at",
  "last_verified_at"
)

$vercelEnvSpecs = @{
  "consulting" = @(
    @("PUBLIC_CONSULTING_INTAKE_ENDPOINT")
  )
  "hub" = @(
    @("HUB_UI_TOKEN"),
    @("HUB_COOKIE_SECRET"),
    @("SUPABASE_URL", "CONSULTING_SUPABASE_URL"),
    @("SUPABASE_SECRET_KEY", "SUPABASE_SERVICE_ROLE_KEY", "CONSULTING_SUPABASE_SERVICE_ROLE_KEY"),
    @("CRON_SECRET"),
    @("CONSULTING_INTAKE_ALLOWED_ORIGINS"),
    @("CONSULTING_INTAKE_SUCCESS_URL"),
    @("CONSOLE_SOURCE_ADAPTER"),
    @("CONSOLE_PLAYBOOK_REPO")
  )
}

$optionalVercelEnvSpecs = @{
  "consulting" = @(
    @("PUBLIC_FORMSPREE_ENDPOINT")
  )
}

$results = New-Object System.Collections.Generic.List[object]

function Get-RepoPath {
  param([string]$Repo)
  return Join-Path $PortfolioRoot $Repo
}

function Add-Result {
  param(
    [ValidateSet("green", "yellow", "red")]
    [string]$Status,
    [string]$Area,
    [string]$Check,
    [string]$Detail
  )

  $results.Add([pscustomobject]@{
    Status = $Status
    Area = $Area
    Check = $Check
    Detail = $Detail
  }) | Out-Null
}

function Test-Command {
  param([string]$Name)
  return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-SupabaseCommand {
  if (Test-Command "supabase") {
    return @("supabase")
  }

  if (Test-Command "npx") {
    return @("npx", "supabase")
  }

  return @()
}

function Invoke-Captured {
  param(
    [string]$WorkDir,
    [string[]]$Command
  )

  Push-Location $WorkDir
  try {
    $arguments = if ($Command.Length -gt 1) { @($Command[1..($Command.Length - 1)]) } else { @() }
    $output = & $Command[0] @arguments 2>&1
    return [pscustomobject]@{
      ExitCode = $LASTEXITCODE
      Output = ($output -join "`n")
    }
  }
  finally {
    Pop-Location
  }
}

function Get-ConfiguredHealthUrls {
  $urls = New-Object System.Collections.Generic.List[string]

  foreach ($url in $HealthUrl) {
    if ($url) {
      $urls.Add($url) | Out-Null
    }
  }

  $listEnv = [Environment]::GetEnvironmentVariable("PORTFOLIO_HEALTH_URLS")
  if ($listEnv) {
    foreach ($url in ($listEnv -split "[,;]")) {
      $trimmed = $url.Trim()
      if ($trimmed) {
        $urls.Add($trimmed) | Out-Null
      }
    }
  }

  foreach ($name in @("HUB_HEALTH_URL", "CONSULTING_HEALTH_URL")) {
    $value = [Environment]::GetEnvironmentVariable($name)
    if ($value) {
      $urls.Add($value) | Out-Null
    }
  }

  if ($urls.Count -eq 0) {
    $urls.Add("https://onhand.dev/health") | Out-Null
  }

  return $urls | Select-Object -Unique
}

function Test-RepoStatus {
  foreach ($repo in $repos) {
    $path = Get-RepoPath $repo
    if (-not (Test-Path -LiteralPath $path)) {
      Add-Result "red" "repo" $repo "missing at $path"
      continue
    }

    if (-not (Test-Path -LiteralPath (Join-Path $path ".git"))) {
      Add-Result "red" "repo" $repo "not a git checkout"
      continue
    }

    Push-Location $path
    try {
      $branch = git branch --show-current
      $status = git status --short
      $upstream = git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>$null
      $branchDetail = if ($upstream) { "$branch tracking $upstream" } else { "$branch with no upstream" }

      if ($branch -ne "main") {
        Add-Result "yellow" "repo" $repo "$branchDetail; expected main for portfolio ops"
      }
      elseif ($status) {
        Add-Result "yellow" "repo" $repo "$branchDetail; dirty working tree"
      }
      else {
        Add-Result "green" "repo" $repo "$branchDetail; clean"
      }
    }
    finally {
      Pop-Location
    }
  }
}

function Test-ManifestCoverage {
  foreach ($repo in $repos) {
    $path = Get-RepoPath $repo
    $manifest = Join-Path $path ".repo.yml"
    if (-not (Test-Path -LiteralPath $manifest)) {
      Add-Result "red" ".repo.yml" $repo "missing manifest"
      continue
    }

    $content = Get-Content -LiteralPath $manifest -Raw
    $missing = @()
    foreach ($field in $requiredManifestFields) {
      if ($content -notmatch "(?m)^$([regex]::Escape($field))\s*:") {
        $missing += $field
      }
    }

    if ($missing.Count -gt 0) {
      Add-Result "red" ".repo.yml" $repo "missing field(s): $($missing -join ', ')"
    }
    else {
      Add-Result "green" ".repo.yml" $repo "required field coverage present"
    }
  }
}

function Test-HubRegistry {
  if ($StatusOnly) {
    Add-Result "yellow" "hub-registry" "validation" "skipped by -StatusOnly"
    return
  }

  $path = Get-RepoPath "hub-registry"
  if (-not (Test-Path -LiteralPath $path)) {
    Add-Result "red" "hub-registry" "validation" "missing checkout"
    return
  }

  $result = Invoke-Captured $path @("npm", "test")
  if ($result.ExitCode -eq 0) {
    Add-Result "green" "hub-registry" "validation" "npm test passed"
  }
  else {
    Add-Result "red" "hub-registry" "validation" "npm test failed with exit code $($result.ExitCode)"
  }
}

function Test-HealthUrls {
  $urls = @(Get-ConfiguredHealthUrls)
  if ($urls.Count -eq 0) {
    Add-Result "yellow" "health" "configured URLs" "none configured; set -HealthUrl or PORTFOLIO_HEALTH_URLS"
    return
  }

  foreach ($url in $urls) {
    try {
      $response = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec 10 -MaximumRedirection 3
      if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
        Add-Result "green" "health" $url "HTTP $($response.StatusCode)"
      }
      else {
        Add-Result "red" "health" $url "HTTP $($response.StatusCode)"
      }
    }
    catch {
      Add-Result "red" "health" $url $_.Exception.Message
    }
  }
}

function Test-GitHubActions {
  if (-not (Test-Command "gh")) {
    Add-Result "yellow" "github-actions" "gh" "GitHub CLI unavailable"
    return
  }

  foreach ($repo in $repos) {
    $path = Get-RepoPath $repo
    if (-not (Test-Path -LiteralPath (Join-Path $path ".github\workflows"))) {
      Add-Result "yellow" "github-actions" $repo "no workflows directory"
      continue
    }

    $result = Invoke-Captured $path @("gh", "run", "list", "--limit", "1", "--json", "status,conclusion,workflowName,headBranch")
    if ($result.ExitCode -ne 0) {
      Add-Result "yellow" "github-actions" $repo "gh run list unavailable or not authenticated"
      continue
    }

    try {
      $runs = $result.Output | ConvertFrom-Json
      if (-not $runs -or $runs.Count -eq 0) {
        Add-Result "yellow" "github-actions" $repo "no recent workflow runs"
        continue
      }

      $run = @($runs)[0]
      if ($run.status -eq "completed" -and $run.conclusion -eq "success") {
        Add-Result "green" "github-actions" $repo "$($run.workflowName) on $($run.headBranch): success"
      }
      elseif ($run.status -eq "completed") {
        Add-Result "red" "github-actions" $repo "$($run.workflowName) on $($run.headBranch): $($run.conclusion)"
      }
      else {
        Add-Result "yellow" "github-actions" $repo "$($run.workflowName) on $($run.headBranch): $($run.status)"
      }
    }
    catch {
      Add-Result "yellow" "github-actions" $repo "could not parse gh output"
    }
  }
}

function Test-VercelEnvPresence {
  if (-not (Test-Command "vercel")) {
    Add-Result "yellow" "vercel-env" "vercel" "Vercel CLI unavailable"
    return
  }

  foreach ($repo in $vercelEnvSpecs.Keys) {
    $path = Get-RepoPath $repo
    if (-not (Test-Path -LiteralPath (Join-Path $path ".vercel"))) {
      Add-Result "yellow" "vercel-env" $repo "not linked locally with .vercel"
      continue
    }

    $result = Invoke-Captured $path @("vercel", "env", "ls")
    if ($result.ExitCode -ne 0) {
      Add-Result "yellow" "vercel-env" $repo "unable to list env names"
      continue
    }

    $missing = @()
    foreach ($alternatives in $vercelEnvSpecs[$repo]) {
      $found = $false
      foreach ($name in $alternatives) {
        if ($result.Output -match "(?m)\b$([regex]::Escape($name))\b") {
          $found = $true
          break
        }
      }
      if (-not $found) {
        $missing += ($alternatives -join " or ")
      }
    }

    if ($missing.Count -gt 0) {
      Add-Result "red" "vercel-env" $repo "missing env name(s): $($missing -join '; ')"
    }
    else {
      Add-Result "green" "vercel-env" $repo "required env names present"
    }

    if ($optionalVercelEnvSpecs.ContainsKey($repo)) {
      $optionalMissing = @()
      foreach ($alternatives in $optionalVercelEnvSpecs[$repo]) {
        $found = $false
        foreach ($name in $alternatives) {
          if ($result.Output -match "(?m)\b$([regex]::Escape($name))\b") {
            $found = $true
            break
          }
        }
        if (-not $found) {
          $optionalMissing += ($alternatives -join " or ")
        }
      }

      if ($optionalMissing.Count -gt 0) {
        Add-Result "yellow" "vercel-env" $repo "optional fallback env missing: $($optionalMissing -join '; ')"
      }
      else {
        Add-Result "green" "vercel-env" $repo "optional fallback env names present"
      }
    }
  }
}

function Test-SupabaseCli {
  $hubPath = Get-RepoPath "hub"
  $supabasePath = Join-Path $hubPath "supabase"
  if (-not (Test-Path -LiteralPath $supabasePath)) {
    Add-Result "yellow" "supabase" "hub" "no supabase directory"
    return
  }

  $migrations = Get-ChildItem -LiteralPath (Join-Path $supabasePath "migrations") -Filter "*.sql" -ErrorAction SilentlyContinue
  if ($migrations.Count -gt 0) {
    Add-Result "green" "supabase" "migrations" "$($migrations.Count) migration file(s) present"
  }
  else {
    Add-Result "red" "supabase" "migrations" "no migration files found"
  }

  $supabaseCommand = Get-SupabaseCommand
  if ($supabaseCommand.Count -eq 0) {
    Add-Result "yellow" "supabase" "cli" "Supabase CLI unavailable"
    return
  }

  $migrationList = Invoke-Captured $hubPath ($supabaseCommand + @("migration", "list"))
  if ($migrationList.ExitCode -eq 0) {
    Add-Result "green" "supabase" "migration list" "CLI check passed; output suppressed"
  }
  else {
    Add-Result "yellow" "supabase" "migration list" "CLI check unavailable; output suppressed"
  }

  $runLocalStatus = [Environment]::GetEnvironmentVariable("PORTFOLIO_RUN_SUPABASE_STATUS")
  if ($runLocalStatus -ne "1") {
    Add-Result "yellow" "supabase" "status" "skipped by default; set PORTFOLIO_RUN_SUPABASE_STATUS=1 for local Docker status"
    return
  }

  $status = Invoke-Captured $hubPath ($supabaseCommand + @("status"))
  if ($status.ExitCode -eq 0) {
    Add-Result "green" "supabase" "status" "CLI check passed; output suppressed"
  }
  else {
    Add-Result "yellow" "supabase" "status" "CLI check unavailable; output suppressed"
  }
}

function Write-Results {
  Write-Host "Portfolio ops check"
  Write-Host "Portfolio root: $PortfolioRoot"
  Write-Host "Read-only by design: sibling repos are inspected but not mutated."
  Write-Host ""

  foreach ($result in $results) {
    $color = switch ($result.Status) {
      "green" { "Green" }
      "yellow" { "Yellow" }
      "red" { "Red" }
    }
    Write-Host ("[{0}] {1} :: {2} :: {3}" -f $result.Status.ToUpperInvariant(), $result.Area, $result.Check, $result.Detail) -ForegroundColor $color
  }

  $red = @($results | Where-Object { $_.Status -eq "red" }).Count
  $yellow = @($results | Where-Object { $_.Status -eq "yellow" }).Count
  $green = @($results | Where-Object { $_.Status -eq "green" }).Count
  $overall = if ($red -gt 0) { "RED" } elseif ($yellow -gt 0) { "YELLOW" } else { "GREEN" }

  Write-Host ""
  Write-Host "Summary: $overall ($green green, $yellow yellow, $red red)"
}

Test-RepoStatus
Test-ManifestCoverage
Test-HubRegistry
Test-HealthUrls
Test-GitHubActions
Test-VercelEnvPresence
Test-SupabaseCli
Write-Results

if (($results | Where-Object { $_.Status -eq "red" })) {
  exit 1
}

exit 0
