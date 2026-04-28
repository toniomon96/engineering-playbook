[CmdletBinding()]
param(
  [string]$VaultName = "Toni Portfolio Ops",
  [string]$RegistryPath = (Join-Path (Split-Path -Parent $PSScriptRoot) "secrets\portfolio-secret-register.json"),
  [switch]$CheckFields,
  [switch]$IncludeInternalConfig,
  [switch]$Strict
)

$ErrorActionPreference = "Stop"

$script:Results = New-Object System.Collections.Generic.List[object]

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

function Find-OpExecutable {
  $command = Get-Command "op" -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $wingetPackageRoot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
  if (Test-Path -LiteralPath $wingetPackageRoot) {
    $candidate = Get-ChildItem -LiteralPath $wingetPackageRoot -Recurse -Filter "op.exe" -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName -match "1Password\.CLI" } |
      Select-Object -First 1
    if ($candidate) {
      return $candidate.FullName
    }
  }

  return $null
}

function Invoke-OpJson {
  param(
    [string]$OpPath,
    [string[]]$Arguments
  )

  $output = & $OpPath @Arguments "--format" "json" 2>&1
  $exitCode = $LASTEXITCODE
  if ($exitCode -ne 0) {
    return [pscustomobject]@{
      ExitCode = $exitCode
      Json = $null
    }
  }

  try {
    return [pscustomobject]@{
      ExitCode = 0
      Json = ($output -join "`n" | ConvertFrom-Json)
    }
  }
  catch {
    return [pscustomobject]@{
      ExitCode = 1
      Json = $null
    }
  }
}

function Get-ItemEnvironment {
  param([string]$ItemName)

  if ($ItemName -match "\s/\s(?<env>production|preview|development|local|test|automation)$") {
    return $Matches.env
  }

  return $null
}

function Get-EnvironmentAliases {
  param([string]$Environment)

  switch ($Environment) {
    "automation" { return @("production", "local") }
    "development" { return @("development", "local") }
    default { return @($Environment) }
  }
}

function Get-ExpectedFieldsForItem {
  param(
    [object]$Project,
    [string]$ItemName,
    [string[]]$IncludedClassifications
  )

  $environment = Get-ItemEnvironment $ItemName
  if (-not $environment) {
    return @()
  }

  $aliases = Get-EnvironmentAliases $environment
  $fields = New-Object System.Collections.Generic.List[string]
  foreach ($variable in $Project.variables) {
    $classification = [string]$variable.classification
    if ($classification -notin $IncludedClassifications) {
      continue
    }

    $environments = @($variable.environments | ForEach-Object { [string]$_ })
    if (@($environments | Where-Object { $_ -in $aliases }).Count -gt 0) {
      $fields.Add([string]$variable.name) | Out-Null
    }
  }

  return @($fields | Sort-Object -Unique)
}

function Get-FieldLabels {
  param([object]$Node)

  $labels = New-Object System.Collections.Generic.List[string]
  if ($null -eq $Node) {
    return $labels
  }

  if ($Node -is [System.Collections.IEnumerable] -and $Node -isnot [string]) {
    foreach ($item in $Node) {
      foreach ($label in Get-FieldLabels $item) {
        $labels.Add($label) | Out-Null
      }
    }
    return $labels
  }

  if ($Node.PSObject.Properties) {
    $labelProperty = $Node.PSObject.Properties["label"]
    if ($labelProperty -and $labelProperty.Value) {
      $labels.Add([string]$labelProperty.Value) | Out-Null
    }

    foreach ($property in $Node.PSObject.Properties) {
      foreach ($label in Get-FieldLabels $property.Value) {
        $labels.Add($label) | Out-Null
      }
    }
  }

  return $labels
}

Write-Host "1Password portfolio secret check"
Write-Host "Vault: $VaultName"
Write-Host "Registry: $RegistryPath"
Write-Host "Mode: value-free report; secret values are never printed."
Write-Host ""

$opPath = Find-OpExecutable
if (-not $opPath) {
  Add-Result "red" "op-cli" "install" "1Password CLI was not found" "Install with: winget install -e --id AgileBits.1Password.CLI"
}
else {
  Add-Result "green" "op-cli" "install" "1Password CLI found" "Restart PowerShell if the op alias is not on PATH yet."
}

if (-not (Test-Path -LiteralPath $RegistryPath)) {
  Add-Result "red" "registry" "portfolio-secret-register.json" "registry file missing" "Restore secrets/portfolio-secret-register.json."
}

if ($opPath -and (Test-Path -LiteralPath $RegistryPath)) {
  $registry = Get-Content -LiteralPath $RegistryPath -Raw | ConvertFrom-Json
  $vaultList = Invoke-OpJson $opPath @("vault", "list")
  if ($vaultList.ExitCode -ne 0) {
    Add-Result "yellow" "op-auth" "sign-in" "could not list 1Password vaults from this shell" "Open and unlock 1Password, enable Settings > Developer > Integrate with 1Password CLI, then run op vault list."
  }
  else {
    $vault = @($vaultList.Json | Where-Object { $_.name -eq $VaultName }) | Select-Object -First 1
    if (-not $vault) {
      Add-Result "yellow" "op-vault" $VaultName "vault missing or not visible to CLI" "Create the vault in 1Password or grant this account access."
    }
    else {
      Add-Result "green" "op-vault" $VaultName "vault is visible to CLI" "None."

      $itemList = Invoke-OpJson $opPath @("item", "list", "--vault", $VaultName)
      if ($itemList.ExitCode -ne 0) {
        Add-Result "yellow" "op-items" $VaultName "could not list items" "Confirm 1Password CLI access to the vault."
      }
      else {
        $itemNames = @($itemList.Json | ForEach-Object { [string]$_.title })
        $includedClassifications = @("secret", "sensitive-config", "public-config")
        if ($IncludeInternalConfig) {
          $includedClassifications += "internal-config"
        }

        foreach ($project in $registry.projects) {
          foreach ($itemName in @($project.vault_items | ForEach-Object { [string]$_ })) {
            if ($itemName -notin $itemNames) {
              $status = if ($Strict -and $itemName -match "/ production$") { "red" } else { "yellow" }
              Add-Result $status "op-item" $itemName "item missing" "Create this item in the $VaultName vault."
              continue
            }

            Add-Result "green" "op-item" $itemName "item exists" "None."

            if ($CheckFields) {
              $expectedFields = @(Get-ExpectedFieldsForItem $project $itemName $includedClassifications)
              if ($expectedFields.Count -eq 0) {
                continue
              }

              $item = Invoke-OpJson $opPath @("item", "get", $itemName, "--vault", $VaultName)
              if ($item.ExitCode -ne 0) {
                Add-Result "yellow" "op-fields" $itemName "could not inspect field labels" "Open the item manually and compare against the registry."
                continue
              }

              $labels = @(Get-FieldLabels $item.Json | Sort-Object -Unique)
              $missingFields = @($expectedFields | Where-Object { $_ -notin $labels })
              if ($missingFields.Count -gt 0) {
                $status = if ($Strict -and $itemName -match "/ production$") { "red" } else { "yellow" }
                Add-Result $status "op-fields" $itemName "missing field label(s): $($missingFields -join ', ')" "Add fields named exactly like the env vars. Do not paste values into the repo."
              }
              else {
                Add-Result "green" "op-fields" $itemName "$($expectedFields.Count) expected field label(s) present" "None."
              }
            }
          }
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

exit 0
