[CmdletBinding()]
param(
  [string]$PortfolioRoot,
  [string[]]$HealthUrl,
  [switch]$StatusOnly
)

$params = @{}
if ($PortfolioRoot) {
  $params["PortfolioRoot"] = $PortfolioRoot
}
if ($HealthUrl) {
  $params["HealthUrl"] = $HealthUrl
}
if ($StatusOnly) {
  $params["StatusOnly"] = $true
}

& (Join-Path $PSScriptRoot "consulting-ops-check.ps1") @params
exit $LASTEXITCODE
