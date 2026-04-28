[CmdletBinding()]
param(
  [string]$PortfolioRoot,
  [string[]]$HealthUrl,
  [string[]]$OwnedRepo = @(),
  [switch]$StatusOnly
)

$ErrorActionPreference = "Stop"

$playbookRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if (-not $PortfolioRoot) {
  $PortfolioRoot = Split-Path -Parent $playbookRoot
}

function New-ActionCheck {
  param(
    [string]$Workflow,
    [string]$Branch,
    [bool]$Required
  )

  return [pscustomobject]@{
    Workflow = $Workflow
    Branch = $Branch
    Required = $Required
  }
}

$repoPolicies = @(
  [pscustomobject]@{
    Name = "consulting"
    ExpectedBranch = "main"
    OwnedExpectedBranch = "main"
    ProtectedBranch = "main"
    Ownership = "owned"
    ValidateManifest = $true
    Actions = @()
  },
  [pscustomobject]@{
    Name = "engineering-playbook"
    ExpectedBranch = "main"
    OwnedExpectedBranch = "main"
    ProtectedBranch = "main"
    Ownership = "owned"
    ValidateManifest = $true
    Actions = @()
  },
  [pscustomobject]@{
    Name = "hub"
    ExpectedBranch = "main"
    OwnedExpectedBranch = "main"
    ProtectedBranch = "main"
    Ownership = "owned"
    ValidateManifest = $true
    Actions = @(
      (New-ActionCheck "ci" "main" $true),
      (New-ActionCheck "security" "main" $true)
    )
  },
  [pscustomobject]@{
    Name = "hub-prompts"
    ExpectedBranch = "main"
    OwnedExpectedBranch = "main"
    ProtectedBranch = "main"
    Ownership = "owned"
    ValidateManifest = $true
    Actions = @()
  },
  [pscustomobject]@{
    Name = "hub-registry"
    ExpectedBranch = "main"
    OwnedExpectedBranch = "main"
    ProtectedBranch = "main"
    Ownership = "owned"
    ValidateManifest = $true
    Actions = @(
      (New-ActionCheck "Validate registry" "main" $true)
    )
  },
  [pscustomobject]@{
    Name = "FamilyTrips"
    ExpectedBranch = "main"
    OwnedExpectedBranch = "main"
    ProtectedBranch = "main"
    Ownership = "owned"
    ValidateManifest = $true
    Actions = @()
  },
  [pscustomobject]@{
    Name = "demario-pickleball-1"
    ExpectedBranch = "master"
    OwnedExpectedBranch = "master"
    ProtectedBranch = "master"
    Ownership = "owned"
    ValidateManifest = $true
    Actions = @(
      (New-ActionCheck "CI" "master" $true)
    )
  },
  [pscustomobject]@{
    Name = "dse-content"
    ExpectedBranch = "dev"
    OwnedExpectedBranch = "dev"
    ProtectedBranch = "main"
    Ownership = "owned"
    ValidateManifest = $true
    Actions = @(
      (New-ActionCheck "WorkIQ Post-Meeting Digest" "main" $false),
      (New-ActionCheck "DSE Automation Scheduled Run" "main" $false)
    )
  },
  [pscustomobject]@{
    Name = "fitness-app"
    ExpectedBranch = "main"
    OwnedExpectedBranch = "dev"
    ProtectedBranch = "main"
    Ownership = "read-only"
    ValidateManifest = $true
    Actions = @(
      (New-ActionCheck "CI" "main" $true),
      (New-ActionCheck "Build iOS" "main" $false),
      (New-ActionCheck "Semgrep" "main" $false)
    )
  }
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

function Test-RepoOwned {
  param([object]$Policy)

  return $Policy.Ownership -ne "read-only" -or $OwnedRepo -contains $Policy.Name -or $OwnedRepo -contains "*"
}

function Get-ExpectedBranch {
  param([object]$Policy)

  if ((Test-RepoOwned $Policy) -and $Policy.OwnedExpectedBranch) {
    return $Policy.OwnedExpectedBranch
  }

  return $Policy.ExpectedBranch
}

function Add-Result {
  param(
    [ValidateSet("green", "yellow", "red")]
    [string]$Status,
    [string]$Area,
    [string]$Check,
    [string]$Detail,
    [string]$NextAction
  )

  if (-not $NextAction) {
    $NextAction = switch ($Status) {
      "green" { "None." }
      "yellow" { "Review if this repo is in scope for the current pass." }
      "red" { "Fix before treating the portfolio as healthy." }
    }
  }

  $results.Add([pscustomobject]@{
    Status = $Status
    Area = $Area
    Check = $Check
    Detail = $Detail
    NextAction = $NextAction
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
  foreach ($policy in $repoPolicies) {
    $repo = $policy.Name
    $path = Get-RepoPath $repo
    $isOwned = Test-RepoOwned $policy
    $area = if ($isOwned) { "repo" } else { "repo-readonly" }

    if (-not (Test-Path -LiteralPath $path)) {
      $status = if ($isOwned) { "red" } else { "yellow" }
      Add-Result $status $area $repo "missing at $path" "Restore the checkout or remove it from repo policy."
      continue
    }

    if (-not (Test-Path -LiteralPath (Join-Path $path ".git"))) {
      $status = if ($isOwned) { "red" } else { "yellow" }
      Add-Result $status $area $repo "not a git checkout" "Restore Git metadata before relying on portfolio status."
      continue
    }

    Push-Location $path
    try {
      $branch = git branch --show-current
      $statusOutput = git status --short
      $upstream = git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>$null
      $expectedBranch = Get-ExpectedBranch $policy
      $mode = if ($isOwned) { "owned" } else { "read-only inventory" }
      $aheadCount = 0
      $behindCount = 0
      if ($upstream) {
        $counts = git rev-list --left-right --count "$upstream...HEAD" 2>$null
        if ($counts) {
          $parts = ($counts -split "\s+") | Where-Object { $_ -ne "" }
          if ($parts.Count -ge 2) {
            $behindCount = [int]$parts[0]
            $aheadCount = [int]$parts[1]
          }
        }
      }
      $drift = @()
      if ($aheadCount -gt 0) { $drift += "ahead $aheadCount" }
      if ($behindCount -gt 0) { $drift += "behind $behindCount" }
      $driftDetail = if ($drift.Count -gt 0) { "; $($drift -join ', ')" } else { "" }
      $branchDetail = if ($upstream) { "$branch tracking $upstream$driftDetail" } else { "$branch with no upstream" }
      $laneDetail = "expected $expectedBranch; protected $($policy.ProtectedBranch); mode $mode"

      if ($branch -ne $expectedBranch) {
        Add-Result "yellow" $area $repo "$branchDetail; $laneDetail" "Switch to $expectedBranch before starting scoped work, unless this is intentional release/hotfix work."
      }
      elseif ($statusOutput) {
        Add-Result "yellow" $area $repo "$branchDetail; dirty working tree; $laneDetail" "Preserve these edits; do not stage, format, or revert without explicit ownership."
      }
      elseif (($aheadCount -gt 0) -or ($behindCount -gt 0)) {
        $nextAction = if ($behindCount -gt 0) { "Fast-forward from $upstream before starting scoped work." } else { "Push or open a PR for local commits before handoff." }
        Add-Result "yellow" $area $repo "$branchDetail; clean; $laneDetail" $nextAction
      }
      else {
        Add-Result "green" $area $repo "$branchDetail; clean; $laneDetail" "None."
      }
    }
    finally {
      Pop-Location
    }
  }
}

function Test-ManifestCoverage {
  foreach ($policy in ($repoPolicies | Where-Object { $_.ValidateManifest })) {
    $repo = $policy.Name
    $path = Get-RepoPath $repo
    $manifest = Join-Path $path ".repo.yml"
    if (-not (Test-Path -LiteralPath $manifest)) {
      Add-Result "red" ".repo.yml" $repo "missing manifest" "Add a root .repo.yml using REPO_REGISTRY_SCHEMA.md."
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
      Add-Result "red" ".repo.yml" $repo "missing field(s): $($missing -join ', ')" "Fill the manifest fields before indexing or cross-repo routing."
    }
    else {
      Add-Result "green" ".repo.yml" $repo "required field coverage present" "None."
    }
  }
}

function Test-HubRegistry {
  if ($StatusOnly) {
    Add-Result "yellow" "hub-registry" "validation" "skipped by -StatusOnly" "Run without -StatusOnly before release or handoff."
    return
  }

  $path = Get-RepoPath "hub-registry"
  if (-not (Test-Path -LiteralPath $path)) {
    Add-Result "red" "hub-registry" "validation" "missing checkout" "Restore hub-registry checkout."
    return
  }

  $result = Invoke-Captured $path @("npm", "test")
  if ($result.ExitCode -eq 0) {
    Add-Result "green" "hub-registry" "validation" "npm test passed" "None."
  }
  else {
    Add-Result "red" "hub-registry" "validation" "npm test failed with exit code $($result.ExitCode)" "Fix registry validation before trusting automation targets."
  }
}

function Test-HealthUrls {
  $urls = @(Get-ConfiguredHealthUrls)
  if ($urls.Count -eq 0) {
    Add-Result "yellow" "health" "configured URLs" "none configured; set -HealthUrl or PORTFOLIO_HEALTH_URLS" "Configure at least one health URL."
    return
  }

  foreach ($url in $urls) {
    try {
      $response = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec 10 -MaximumRedirection 3
      if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
        Add-Result "green" "health" $url "HTTP $($response.StatusCode)" "None."
      }
      else {
        Add-Result "red" "health" $url "HTTP $($response.StatusCode)" "Fix the live endpoint or remove it from configured health checks."
      }
    }
    catch {
      Add-Result "red" "health" $url $_.Exception.Message "Fix the live endpoint or remove it from configured health checks."
    }
  }
}

function Add-ActionResult {
  param(
    [object]$Action,
    [object[]]$Runs,
    [string]$Repo
  )

  $matchingRuns = @($Runs | Where-Object {
    $_.workflowName -eq $Action.Workflow -and (-not $Action.Branch -or $_.headBranch -eq $Action.Branch)
  })

  $label = if ($Action.Branch) { "$($Action.Workflow) on $($Action.Branch)" } else { $Action.Workflow }
  $severity = if ($Action.Required) { "required" } else { "optional" }

  if ($matchingRuns.Count -eq 0) {
    Add-Result "yellow" "github-actions" $Repo "${label}: no recent $severity run found" "Trigger or inspect the workflow if this repo is in scope."
    return
  }

  $run = $matchingRuns[0]
  if ($run.status -eq "completed" -and $run.conclusion -eq "success") {
    Add-Result "green" "github-actions" $Repo "${label}: success" "None."
  }
  elseif ($run.status -eq "completed") {
    $status = if ($Action.Required) { "red" } else { "yellow" }
    $next = if ($Action.Required) { "Fix the workflow before treating this repo as healthy." } else { "Fix or explicitly defer this advisory automation." }
    Add-Result $status "github-actions" $Repo "${label}: $($run.conclusion)" $next
  }
  else {
    Add-Result "yellow" "github-actions" $Repo "${label}: $($run.status)" "Wait for the workflow to finish or inspect it if stuck."
  }
}

function Test-GitHubActions {
  if (-not (Test-Command "gh")) {
    Add-Result "yellow" "github-actions" "gh" "GitHub CLI unavailable" "Install or authenticate gh before relying on workflow status."
    return
  }

  foreach ($policy in $repoPolicies) {
    $repo = $policy.Name
    $path = Get-RepoPath $repo
    if (-not (Test-Path -LiteralPath (Join-Path $path ".github\workflows"))) {
      Add-Result "yellow" "github-actions" $repo "no workflows directory" "No action unless this repo should have CI."
      continue
    }

    if (-not (Test-RepoOwned $policy)) {
      Add-Result "yellow" "github-actions" $repo "read-only inventory; workflow checks skipped" "Run with -OwnedRepo $repo when this session owns the repo."
      continue
    }

    $actions = @($policy.Actions)
    if ($actions.Count -eq 0) {
      Add-Result "yellow" "github-actions" $repo "no required workflow policy configured" "Add required workflow policy if this repo needs CI gating."
      continue
    }

    $result = Invoke-Captured $path @("gh", "run", "list", "--limit", "30", "--json", "status,conclusion,workflowName,headBranch")
    if ($result.ExitCode -ne 0) {
      Add-Result "yellow" "github-actions" $repo "gh run list unavailable or not authenticated" "Authenticate gh or inspect workflow status manually."
      continue
    }

    try {
      $runs = @($result.Output | ConvertFrom-Json)
      if (-not $runs -or $runs.Count -eq 0) {
        Add-Result "yellow" "github-actions" $repo "no recent workflow runs" "Trigger CI when this repo is in scope."
        continue
      }

      foreach ($action in $actions) {
        Add-ActionResult $action $runs $repo
      }
    }
    catch {
      Add-Result "yellow" "github-actions" $repo "could not parse gh output" "Inspect gh output manually."
    }
  }
}

function Test-VercelEnvPresence {
  if (-not (Test-Command "vercel")) {
    Add-Result "yellow" "vercel-env" "vercel" "Vercel CLI unavailable" "Install or authenticate vercel before relying on env checks."
    return
  }

  foreach ($repo in $vercelEnvSpecs.Keys) {
    $path = Get-RepoPath $repo
    if (-not (Test-Path -LiteralPath (Join-Path $path ".vercel"))) {
      Add-Result "yellow" "vercel-env" $repo "not linked locally with .vercel" "Run vercel link if env checks should be local."
      continue
    }

    $result = Invoke-Captured $path @("vercel", "env", "ls")
    if ($result.ExitCode -ne 0) {
      Add-Result "yellow" "vercel-env" $repo "unable to list env names" "Authenticate vercel or inspect env names manually."
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
      Add-Result "red" "vercel-env" $repo "missing env name(s): $($missing -join '; ')" "Set the env names in Vercel without printing secret values."
    }
    else {
      Add-Result "green" "vercel-env" $repo "required env names present" "None."
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
        Add-Result "yellow" "vercel-env" $repo "optional fallback env missing: $($optionalMissing -join '; ')" "Add fallback env only if Formspree remains an intentional backup."
      }
      else {
        Add-Result "green" "vercel-env" $repo "optional fallback env names present" "None."
      }
    }
  }
}

function Test-SupabaseCli {
  $hubPath = Get-RepoPath "hub"
  $supabasePath = Join-Path $hubPath "supabase"
  if (-not (Test-Path -LiteralPath $supabasePath)) {
    Add-Result "yellow" "supabase" "hub" "no supabase directory" "No action unless Hub should own Supabase migrations."
    return
  }

  $migrations = Get-ChildItem -LiteralPath (Join-Path $supabasePath "migrations") -Filter "*.sql" -ErrorAction SilentlyContinue
  if ($migrations.Count -gt 0) {
    Add-Result "green" "supabase" "migrations" "$($migrations.Count) migration file(s) present" "None."
  }
  else {
    Add-Result "red" "supabase" "migrations" "no migration files found" "Add or restore Hub Supabase migration files."
  }

  $supabaseCommand = Get-SupabaseCommand
  if ($supabaseCommand.Count -eq 0) {
    Add-Result "yellow" "supabase" "cli" "Supabase CLI unavailable" "Use npx supabase or install the CLI when migration status matters."
    return
  }

  $migrationList = Invoke-Captured $hubPath ($supabaseCommand + @("migration", "list"))
  if ($migrationList.ExitCode -eq 0) {
    Add-Result "green" "supabase" "migration list" "CLI check passed; output suppressed" "None."
  }
  else {
    Add-Result "yellow" "supabase" "migration list" "CLI check unavailable; output suppressed" "Authenticate Supabase or inspect migration state manually."
  }

  $runLocalStatus = [Environment]::GetEnvironmentVariable("PORTFOLIO_RUN_SUPABASE_STATUS")
  if ($runLocalStatus -ne "1") {
    Add-Result "yellow" "supabase" "status" "skipped by default; set PORTFOLIO_RUN_SUPABASE_STATUS=1 for local Docker status" "Leave skipped unless Docker-backed local status is needed."
    return
  }

  $status = Invoke-Captured $hubPath ($supabaseCommand + @("status"))
  if ($status.ExitCode -eq 0) {
    Add-Result "green" "supabase" "status" "CLI check passed; output suppressed" "None."
  }
  else {
    Add-Result "yellow" "supabase" "status" "CLI check unavailable; output suppressed" "Start Docker or inspect Supabase status manually."
  }
}

function Write-Results {
  Write-Host "Portfolio ops check"
  Write-Host "Portfolio root: $PortfolioRoot"
  Write-Host "Mode: repo-aware inventory; this script inspects sibling repos but does not mutate them."
  if ($OwnedRepo.Count -gt 0) {
    Write-Host "Owned repo override: $($OwnedRepo -join ', ')"
  }
  Write-Host ""

  foreach ($result in $results) {
    $color = switch ($result.Status) {
      "green" { "Green" }
      "yellow" { "Yellow" }
      "red" { "Red" }
    }
    Write-Host ("[{0}] {1} :: {2} :: {3} Next: {4}" -f $result.Status.ToUpperInvariant(), $result.Area, $result.Check, $result.Detail, $result.NextAction) -ForegroundColor $color
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
