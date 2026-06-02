param(
    [string]$Target = "192.168.0.31",
    [string]$User = "qnxuser",
    [string]$WorkDir
)

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")
if (-not $WorkDir) { $WorkDir = Join-Path $root ".work" }

$ifs = Join-Path $WorkDir "bsp\hyp-guest-arm\images\guest-2\qnx800-guest-2.ifs"
if (-not (Test-Path -LiteralPath $ifs)) { throw "Guest B IFS not found: $ifs" }

ssh "$User@$Target" "mkdir -p /qnx/config/upload"
scp $ifs "$User@$Target`:/qnx/config/upload/qnx800-guest-2.ifs"

Write-Host "Uploaded Guest B to /qnx/config/upload/qnx800-guest-2.ifs"
Write-Host "As root on target, move it to /qnx/system_b/guests/qnx-guest-2/qnx800-guest-2.ifs if needed."
