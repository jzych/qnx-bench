param(
    [string]$QnxEnv = $env:QNX_ENV
)

. "$PSScriptRoot\common.ps1"

$resolved = Get-QnxEnvPath -QnxEnv $QnxEnv
Write-Host "QNX_ENV=$resolved"
