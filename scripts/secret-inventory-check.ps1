param(
  [string]$WorkspaceRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
  [string]$RegistryPath = (Join-Path (Split-Path -Parent $PSScriptRoot) "secrets\portfolio-secret-register.json")
)

$ErrorActionPreference = "Stop"

$script:Results = New-Object System.Collections.Generic.List[object]
$allowedClassifications = @(
  "secret",
  "sensitive-config",
  "public-config",
  "internal-config"
)

$repoPaths = @{
  "consulting" = Join-Path $WorkspaceRoot "consulting"
  "hub" = Join-Path $WorkspaceRoot "hub"
  "demario-pickleball-1" = Join-Path $WorkspaceRoot "demario-pickleball-1"
  "fitness-app" = Join-Path $WorkspaceRoot "fitness-app"
  "dse-content" = Join-Path $WorkspaceRoot "dse-content"
  "diagnose-to-plan" = Join-Path (Join-Path $WorkspaceRoot "Projects") "diagnose-to-plan"
}

$envSources = @{
  "consulting" = @(".env.example")
  "hub" = @(".env.example", "deploy\env.template")
  "demario-pickleball-1" = @(".env.local.example")
  "fitness-app" = @(".env.example", ".env.test.example")
  "dse-content" = @(".env.example")
  "diagnose-to-plan" = @(".env.example")
}

$localSecretFiles = @(
  ".env",
  ".env.local",
  ".env.test",
  ".env.production",
  ".env.preview",
  ".env.development"
)

function Add-Result {
  param(
    [ValidateSet("green", "yellow", "red")]
    [string]$Status,
    [string]$Area,
    [string]$Name,
    [string]$Reason,
    [string]$NextAction
  )

  $script:Results.Add([pscustomobject]@{
      Status = $Status
      Area = $Area
      Name = $Name
      Reason = $Reason
      NextAction = $NextAction
    }) | Out-Null
}

function Get-EnvNamesFromFile {
  param([string]$Path)

  $names = New-Object System.Collections.Generic.List[string]
  if (-not (Test-Path -LiteralPath $Path)) {
    return $names
  }

  foreach ($line in Get-Content -LiteralPath $Path) {
    if ($line -match "^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=") {
      $names.Add($Matches[1]) | Out-Null
    }
  }

  return $names
}

function Test-TrackedFile {
  param(
    [string]$RepoPath,
    [string]$RelativePath
  )

  $previous = Get-Location
  try {
    Set-Location -LiteralPath $RepoPath
    git ls-files --error-unmatch -- $RelativePath *> $null
    return $LASTEXITCODE -eq 0
  }
  finally {
    Set-Location $previous
  }
}

function Get-JsonPropertyNames {
  param([object]$Node)

  $names = New-Object System.Collections.Generic.List[string]
  if ($null -eq $Node) {
    return $names
  }

  if ($Node -is [System.Collections.IEnumerable] -and $Node -isnot [string]) {
    foreach ($item in $Node) {
      foreach ($name in Get-JsonPropertyNames $item) {
        $names.Add($name) | Out-Null
      }
    }
    return $names
  }

  if ($Node.PSObject.Properties) {
    foreach ($property in $Node.PSObject.Properties) {
      $names.Add($property.Name) | Out-Null
      foreach ($childName in Get-JsonPropertyNames $property.Value) {
        $names.Add($childName) | Out-Null
      }
    }
  }

  return $names
}

function Test-MatchesPrefixGroup {
  param(
    [string]$Name,
    [object[]]$PrefixGroups
  )

  foreach ($group in $PrefixGroups) {
    if ($Name.StartsWith([string]$group.prefix, [System.StringComparison]::Ordinal)) {
      return $true
    }
  }
  return $false
}

Write-Host "Secret inventory check"
Write-Host "Workspace root: $WorkspaceRoot"
Write-Host "Registry: $RegistryPath"
Write-Host "Mode: value-free metadata check; env values are never printed."
Write-Host ""

if (-not (Test-Path -LiteralPath $RegistryPath)) {
  Add-Result "red" "registry" "portfolio-secret-register.json" "registry file missing" "Create the registry before adding new secrets."
}
else {
  $registry = Get-Content -LiteralPath $RegistryPath -Raw | ConvertFrom-Json

  $forbiddenProperties = @("value", "secret_value", "actual_value", "plaintext", "password_value")
  $foundForbidden = (Get-JsonPropertyNames $registry | Where-Object { $_ -in $forbiddenProperties } | Select-Object -Unique)
  if ($foundForbidden) {
    Add-Result "red" "registry" "forbidden fields" "forbidden value-like fields present: $($foundForbidden -join ', ')" "Remove value-bearing fields from the registry."
  }
  else {
    Add-Result "green" "registry" "value-free schema" "no forbidden value fields found" "None."
  }

  $projectNames = @()
  foreach ($project in $registry.projects) {
    $projectNames += [string]$project.repo
    if (-not $project.repo) {
      Add-Result "red" "registry" "project" "project missing repo name" "Add a repo name."
      continue
    }

    if (-not $project.vault_items -or $project.vault_items.Count -eq 0) {
      Add-Result "yellow" "registry" $project.repo "no vault items listed" "Add one vault item per project/environment."
    }

    $seenNames = @{}
    foreach ($variable in $project.variables) {
      $name = [string]$variable.name
      if (-not $name) {
        Add-Result "red" "registry" $project.repo "variable missing name" "Add the env var name."
        continue
      }
      if ($seenNames.ContainsKey($name)) {
        Add-Result "red" "registry" "$($project.repo)/$name" "duplicate registry entry" "Keep one registry entry per env var."
      }
      $seenNames[$name] = $true

      foreach ($field in @("classification", "provider", "environments", "stored_in", "rotation")) {
        if (-not $variable.$field) {
          Add-Result "red" "registry" "$($project.repo)/$name" "missing field: $field" "Fill required metadata without adding the value."
        }
      }

      if ($variable.classification -and ([string]$variable.classification -notin $allowedClassifications)) {
        Add-Result "red" "registry" "$($project.repo)/$name" "invalid classification: $($variable.classification)" "Use secret, sensitive-config, public-config, or internal-config."
      }

      $looksSecret = $name -match "(SECRET|TOKEN|PASSWORD|PRIVATE_KEY|SERVICE_ROLE|WEBHOOK_URL|SHARED_SECRET|PEPPER)"
      if ($looksSecret -and $variable.classification -eq "public-config") {
        Add-Result "yellow" "classification" "$($project.repo)/$name" "name looks secret but is classified public-config" "Confirm this is intentionally public, otherwise classify as secret."
      }
    }

    if ($project.prefix_groups) {
      foreach ($group in $project.prefix_groups) {
        if (-not $group.prefix -or -not $group.classification -or -not $group.stored_in -or -not $group.rotation) {
          Add-Result "red" "registry" "$($project.repo)/prefix-group" "prefix group missing required metadata" "Fill prefix, classification, stored_in, and rotation."
        }
      }
    }
  }

  foreach ($repo in $envSources.Keys) {
    $repoPath = $repoPaths[$repo]
    if (-not (Test-Path -LiteralPath $repoPath)) {
      Add-Result "yellow" "repo" $repo "checkout not found at $repoPath" "Restore checkout before relying on env coverage."
      continue
    }

    $project = $registry.projects | Where-Object { $_.repo -eq $repo } | Select-Object -First 1
    if (-not $project) {
      Add-Result "red" "registry" $repo "repo missing from registry" "Add a project entry for this repo."
      continue
    }

    $registeredNames = @{}
    foreach ($variable in $project.variables) {
      $registeredNames[[string]$variable.name] = $true
    }

    $sourceNames = New-Object System.Collections.Generic.HashSet[string]
    foreach ($relativeSource in $envSources[$repo]) {
      $sourcePath = Join-Path $repoPath $relativeSource
      if (-not (Test-Path -LiteralPath $sourcePath)) {
        Add-Result "yellow" "env-template" "$repo/$relativeSource" "template missing" "Add or remove this source from the inventory checker."
        continue
      }
      foreach ($name in Get-EnvNamesFromFile $sourcePath) {
        $sourceNames.Add($name) | Out-Null
      }
    }

    foreach ($name in ($sourceNames | Sort-Object)) {
      if (-not $registeredNames.ContainsKey($name) -and -not (Test-MatchesPrefixGroup $name $project.prefix_groups)) {
        Add-Result "yellow" "coverage" "$repo/$name" "env template name not in secret registry" "Classify the variable in secrets/portfolio-secret-register.json."
      }
    }

    if ($sourceNames.Count -gt 0) {
      Add-Result "green" "coverage" $repo "$($sourceNames.Count) env/template name(s) scanned" "None."
    }

    foreach ($relativeSecretFile in $localSecretFiles) {
      $secretPath = Join-Path $repoPath $relativeSecretFile
      if (Test-Path -LiteralPath $secretPath) {
        if (Test-TrackedFile $repoPath $relativeSecretFile) {
          Add-Result "red" "local-env" "$repo/$relativeSecretFile" "local env file is tracked by Git" "Remove it from Git history or stop and rotate exposed values."
        }
        else {
          Add-Result "green" "local-env" "$repo/$relativeSecretFile" "exists locally and is untracked" "None."
        }
      }
    }
  }
}

$rank = @{ red = 3; yellow = 2; green = 1 }
$overall = "green"
foreach ($result in $script:Results) {
  if ($rank[$result.Status] -gt $rank[$overall]) {
    $overall = $result.Status
  }
}

foreach ($result in $script:Results) {
  $label = $result.Status.ToUpperInvariant()
  Write-Host "[$label] $($result.Area) :: $($result.Name) :: $($result.Reason) Next: $($result.NextAction)"
}

$green = ($script:Results | Where-Object Status -eq "green").Count
$yellow = ($script:Results | Where-Object Status -eq "yellow").Count
$red = ($script:Results | Where-Object Status -eq "red").Count
Write-Host ""
Write-Host "Summary: $($overall.ToUpperInvariant()) ($green green, $yellow yellow, $red red)"

if ($red -gt 0) {
  exit 1
}
