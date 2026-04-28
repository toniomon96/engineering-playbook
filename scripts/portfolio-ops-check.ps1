[CmdletBinding()]
param(
  [string]$PortfolioRoot,
  [string[]]$HealthUrl,
  [string[]]$OwnedRepo,
  [switch]$StatusOnly
)

$params = @{}
if ($PortfolioRoot) {
  $params["PortfolioRoot"] = $PortfolioRoot
}
if ($HealthUrl) {
  $params["HealthUrl"] = $HealthUrl
}
if ($OwnedRepo) {
  $params["OwnedRepo"] = $OwnedRepo
}
if ($StatusOnly) {
  $params["StatusOnly"] = $true
}

& (Join-Path $PSScriptRoot "consulting-ops-check.ps1") @params
exit $LASTEXITCODE
