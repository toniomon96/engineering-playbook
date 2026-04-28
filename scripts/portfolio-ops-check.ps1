[CmdletBinding()]
param(
  [string]$PortfolioRoot,
  [string[]]$HealthUrl,
  [switch]$StatusOnly
)

$argsList = @()
if ($PortfolioRoot) {
  $argsList += @("-PortfolioRoot", $PortfolioRoot)
}
foreach ($url in $HealthUrl) {
  $argsList += @("-HealthUrl", $url)
}
if ($StatusOnly) {
  $argsList += "-StatusOnly"
}

& (Join-Path $PSScriptRoot "consulting-ops-check.ps1") @argsList
exit $LASTEXITCODE
