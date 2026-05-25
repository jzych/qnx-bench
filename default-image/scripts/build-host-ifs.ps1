param(
    [string]$QnxEnv = $env:QNX_ENV,
    [string]$WorkDir,
    [string]$Target = "screen-remote-debug-wifi-hypervisor"
)

. "$PSScriptRoot\..\..\tools\common.ps1"

if (-not $WorkDir) { $WorkDir = Join-RepoPath ".work" }

$qnxEnvResolved = Get-QnxEnvPath -QnxEnv $QnxEnv
$imagesDir = Resolve-RequiredPath -Path (Join-Path $WorkDir "bsp\rpi5-psb\images") -Description "Raspberry Pi 5 BSP images directory"

Invoke-QnxCommand -QnxEnv $qnxEnvResolved -Command "make -C `"$imagesDir`" $Target"

$ifs = Join-Path $imagesDir "ifs-rpi5.bin"
Resolve-RequiredPath -Path $ifs -Description "host IFS output" | Out-Null
Write-Host "Host IFS ready: $ifs"
