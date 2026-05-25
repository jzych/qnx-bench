param(
    [string]$QnxEnv = $env:QNX_ENV,
    [string]$Rpi5BspSource,
    [string]$HypGuestBspSource,
    [string]$BootSource
)

. "$PSScriptRoot\common.ps1"

$envPath = Get-QnxEnvPath -QnxEnv $QnxEnv
Write-Host "QNX env: $envPath"

if ($Rpi5BspSource) {
    Resolve-RequiredPath -Path $Rpi5BspSource -Description "Raspberry Pi 5 BSP source" | Out-Null
}
if ($HypGuestBspSource) {
    Resolve-RequiredPath -Path $HypGuestBspSource -Description "Hypervisor guest BSP source" | Out-Null
}
if ($BootSource) {
    Resolve-RequiredPath -Path $BootSource -Description "Raspberry Pi boot source" | Out-Null
}

Invoke-QnxCommand -QnxEnv $envPath -Command "where mkqnx6fsimg"
Invoke-QnxCommand -QnxEnv $envPath -Command "where mkifs"
Invoke-QnxCommand -QnxEnv $envPath -Command "where make"

Write-Host "Prerequisite command checks passed."
