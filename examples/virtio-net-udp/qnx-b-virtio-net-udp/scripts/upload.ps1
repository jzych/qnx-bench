param(
    [Parameter(Mandatory = $true)]
    [string]$Target,
    [string]$User = "qnxuser",
    [string]$WorkDir
)

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")
if (-not $WorkDir) { $WorkDir = Join-Path $root ".work" }

$ifs = Join-Path $WorkDir "bsp\hyp-guest-arm\images\guest-2\qnx800-guest-2-virtio-net-udp.ifs"
if (-not (Test-Path -LiteralPath $ifs)) { throw "Guest B virtio-net UDP IFS not found: $ifs" }

ssh "$User@$Target" "mkdir -p /qnx/config/upload"
scp $ifs "$User@$Target`:/qnx/config/upload/qnx800-guest-2-virtio-net-udp.ifs"

Write-Host "Uploaded Guest B to /qnx/config/upload/qnx800-guest-2-virtio-net-udp.ifs"
