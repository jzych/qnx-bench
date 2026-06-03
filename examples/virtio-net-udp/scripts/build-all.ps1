param(
    [string]$QnxEnv = $env:QNX_ENV,
    [string]$WorkDir
)

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
if (-not $WorkDir) { $WorkDir = Join-Path $root ".work" }

& "$PSScriptRoot\..\qnx-a-virtio-net-udp\scripts\build.ps1" -QnxEnv $QnxEnv -WorkDir $WorkDir
& "$PSScriptRoot\..\qnx-b-virtio-net-udp\scripts\build.ps1" -QnxEnv $QnxEnv -WorkDir $WorkDir
