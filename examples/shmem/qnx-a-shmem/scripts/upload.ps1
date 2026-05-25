param(
    [string]$Target = "192.168.0.31",
    [string]$User = "qnxuser",
    [string]$WorkDir
)

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")
if (-not $WorkDir) { $WorkDir = Join-Path $root ".work" }

$ifs = Join-Path $WorkDir "bsp\hyp-guest-arm\images\guest-1\qnx800-guest-aarch64-le.ifs"
if (-not (Test-Path -LiteralPath $ifs)) { throw "Guest A IFS not found: $ifs" }

ssh "$User@$Target" "mkdir -p /qnx/config/upload"
scp $ifs "$User@$Target`:/qnx/config/upload/qnx800-guest-1.ifs"

Write-Host "Uploaded Guest A to /qnx/config/upload/qnx800-guest-1.ifs"
Write-Host "As root on target, move it to /qnx/system_a/guests/qnx-guest-1/qnx800-guest-1.ifs if needed."
