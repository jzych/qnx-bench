param(
    [string]$Target = "192.168.0.31",
    [string]$User = "qnxuser",
    [string]$WorkDir
)

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
if (-not $WorkDir) { $WorkDir = Join-Path $root ".work" }

& "$PSScriptRoot\..\qnx-a-shmem\scripts\upload.ps1" -Target $Target -User $User -WorkDir $WorkDir
& "$PSScriptRoot\..\qnx-b-shmem\scripts\upload.ps1" -Target $Target -User $User -WorkDir $WorkDir

scp "$PSScriptRoot\install-uploaded-on-target.sh" "$User@$Target`:/qnx/config/upload/install-shmem-guests.sh"

Write-Host ""
Write-Host "Uploaded install helper to /qnx/config/upload/install-shmem-guests.sh"
Write-Host "On the target run:"
Write-Host "  su root"
Write-Host "  sh /qnx/config/upload/install-shmem-guests.sh"
