[CmdletBinding()]
param(
  [string]$PortfolioRoot,
  [switch]$StatusOnly,
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

$playbookRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if (-not $PortfolioRoot) {
  $PortfolioRoot = Split-Path -Parent $playbookRoot
}

$repos = @(
  "consulting",
  "hub",
  "engineering-playbook",
  "hub-prompts",
  "hub-registry",
  "FamilyTrips",
  "demario-pickleball-1",
  "dse-content"
)

function Write-Section {
  param([string]$Title)
  Write-Host ""
  Write-Host "== $Title =="
}

function Get-RepoPath {
  param([string]$Repo)
  return Join-Path $PortfolioRoot $Repo
}

function Invoke-CheckedCommand {
  param(
    [string]$Name,
    [string]$WorkDir,
    [string[]]$Command
  )

  Write-Section $Name
  if (-not (Test-Path -LiteralPath $WorkDir)) {
    throw "Missing expected repo path: $WorkDir"
  }

  Push-Location $WorkDir
  try {
    Write-Host "$($Command -join ' ')"
    & $Command[0] $Command[1..($Command.Length - 1)]
    if ($LASTEXITCODE -ne 0) {
      throw "$Name failed with exit code $LASTEXITCODE"
    }
  }
  finally {
    Pop-Location
  }
}

Write-Host "Consulting ops check"
Write-Host "Portfolio root: $PortfolioRoot"
Write-Host "Excluded by design: fitness-app"

Write-Section "Repo Status"
foreach ($repo in $repos) {
  $path = Get-RepoPath $repo
  if (-not (Test-Path -LiteralPath $path)) {
    Write-Host "$repo :: missing"
    continue
  }

  Push-Location $path
  try {
    $branch = git branch --show-current
    $status = git status --short
    if ($status) {
      Write-Host "$repo :: $branch :: dirty"
      $status | ForEach-Object { Write-Host "  $_" }
    }
    else {
      Write-Host "$repo :: $branch :: clean"
    }
  }
  finally {
    Pop-Location
  }
}

if ($StatusOnly) {
  Write-Host ""
  Write-Host "StatusOnly set; validation commands skipped."
  exit 0
}

Invoke-CheckedCommand `
  -Name "hub-registry validation" `
  -WorkDir (Get-RepoPath "hub-registry") `
  -Command @("npm", "test")

Invoke-CheckedCommand `
  -Name "hub-prompts validation" `
  -WorkDir (Get-RepoPath "hub-prompts") `
  -Command @("npm", "test")

if ($SkipBuild) {
  Write-Host ""
  Write-Host "SkipBuild set; consulting build skipped."
}
else {
  Invoke-CheckedCommand `
    -Name "consulting build" `
    -WorkDir (Get-RepoPath "consulting") `
    -Command @("npm", "run", "build")
}

Write-Host ""
Write-Host "Consulting ops check passed."
