param(
    [string]$QnxEnv = $env:QNX_ENV,
    [string]$WorkDir,
    [string]$BootSource,
    [string]$HostTarget = "screen-remote-debug-wifi-hypervisor",
    [string]$OutputDir,
    [switch]$SkipHostBuild,
    [switch]$SkipLayoutBuild
)

. "$PSScriptRoot\..\tools\common.ps1"

if (-not $WorkDir) { $WorkDir = Join-RepoPath ".work" }
if (-not $OutputDir) { $OutputDir = Join-RepoPath ".work\output\default-image" }

$qnxEnvResolved = Get-QnxEnvPath -QnxEnv $QnxEnv

& "$PSScriptRoot\scripts\apply-rpi5-host-overlay.ps1" -WorkDir $WorkDir

if (-not $SkipHostBuild) {
    & "$PSScriptRoot\scripts\build-host-ifs.ps1" `
        -QnxEnv $qnxEnvResolved `
        -WorkDir $WorkDir `
        -Target $HostTarget
}

if (-not $SkipLayoutBuild) {
    if ([string]::IsNullOrWhiteSpace($BootSource)) {
        throw "BootSource is required unless -SkipLayoutBuild is used."
    }
    & "$PSScriptRoot\scripts\build-gpt-image.ps1" `
        -QnxEnv $qnxEnvResolved `
        -WorkDir $WorkDir `
        -BootSource $BootSource `
        -OutputDir $OutputDir
}

Write-Host "Default image flow completed."
