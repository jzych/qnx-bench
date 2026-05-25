param(
    [string]$QnxEnv = $env:QNX_ENV,
    [string]$WorkDir
)

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
if (-not $WorkDir) { $WorkDir = Join-Path $root ".work" }

& "$PSScriptRoot\..\qnx-a-shmem\scripts\build.ps1" -QnxEnv $QnxEnv -WorkDir $WorkDir
& "$PSScriptRoot\..\qnx-b-shmem\scripts\build.ps1" -QnxEnv $QnxEnv -WorkDir $WorkDir
