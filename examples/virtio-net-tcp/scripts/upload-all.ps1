param(
    [string]$Target = "192.168.0.31",
    [string]$User = "qnxuser",
    [string]$WorkDir
)

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
if (-not $WorkDir) { $WorkDir = Join-Path $root ".work" }

& "$PSScriptRoot\..\qnx-a-virtio-net-tcp\scripts\upload.ps1" -Target $Target -User $User -WorkDir $WorkDir
& "$PSScriptRoot\..\qnx-b-virtio-net-tcp\scripts\upload.ps1" -Target $Target -User $User -WorkDir $WorkDir

scp "$PSScriptRoot\install-uploaded-on-target.sh" "$User@$Target`:/qnx/config/upload/install-virtio-net-tcp-guests.sh"
scp "$PSScriptRoot\run-on-target.sh" "$User@$Target`:/qnx/config/upload/run-virtio-net-tcp-on-target.sh"
scp "$PSScriptRoot\verify-on-target.sh" "$User@$Target`:/qnx/config/upload/verify-virtio-net-tcp-on-target.sh"
scp "$PSScriptRoot\..\config\qnx800-guest-1-virtio-net-tcp.qvmconf" "$User@$Target`:/qnx/config/upload/qnx800-guest-1-virtio-net-tcp.qvmconf"
scp "$PSScriptRoot\..\config\qnx800-guest-2-virtio-net-tcp.qvmconf" "$User@$Target`:/qnx/config/upload/qnx800-guest-2-virtio-net-tcp.qvmconf"

Write-Host ""
Write-Host "Uploaded virtio-net TCP install helper to /qnx/config/upload/install-virtio-net-tcp-guests.sh"
Write-Host "On the target run:"
Write-Host "  su root"
Write-Host "  sh /qnx/config/upload/install-virtio-net-tcp-guests.sh"
