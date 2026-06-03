param(
    [string]$Target = "192.168.0.31",
    [string]$User = "qnxuser",
    [string]$WorkDir
)

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")
if (-not $WorkDir) { $WorkDir = Join-Path $root ".work" }

$ifs = Join-Path $WorkDir "bsp\hyp-guest-arm\images\guest-1\qnx800-guest-1-virtio-net-tcp.ifs"
if (-not (Test-Path -LiteralPath $ifs)) { throw "Guest A virtio-net TCP IFS not found: $ifs" }

ssh "$User@$Target" "mkdir -p /qnx/config/upload"
scp $ifs "$User@$Target`:/qnx/config/upload/qnx800-guest-1-virtio-net-tcp.ifs"

Write-Host "Uploaded Guest A to /qnx/config/upload/qnx800-guest-1-virtio-net-tcp.ifs"
