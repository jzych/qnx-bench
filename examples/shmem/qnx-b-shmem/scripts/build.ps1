param(
    [string]$QnxEnv = $env:QNX_ENV,
    [string]$WorkDir
)

. "$PSScriptRoot\..\..\..\..\tools\common.ps1"

if (-not $WorkDir) { $WorkDir = Join-RepoPath ".work" }

$qnxEnvResolved = Get-QnxEnvPath -QnxEnv $QnxEnv
$guestRoot = Resolve-RequiredPath -Path (Join-Path $WorkDir "bsp\hyp-guest-arm") -Description "Hypervisor guest BSP workspace"
$appDir = Join-Path $guestRoot "src\apps\hypervisor\demos\telemetry-consumer"
$imageDir = Join-Path $guestRoot "images\guest-2"
$buildFile = Join-Path $imageDir "qnx800-guest-a.build"

Resolve-RequiredPath -Path $appDir -Description "consumer app directory" | Out-Null
Resolve-RequiredPath -Path $imageDir -Description "guest 2 image directory" | Out-Null

Copy-Item -LiteralPath (Join-Path $PSScriptRoot "..\src\telemetry-consumer.cpp") -Destination (Join-Path $appDir "telemetry-consumer.cpp") -Force
$oldC = Join-Path $appDir "telemetry-consumer.c"
if (Test-Path -LiteralPath $oldC) { Remove-Item -LiteralPath $oldC -Force }

if (Test-Path -LiteralPath $buildFile) {
    $content = Get-Content -LiteralPath $buildFile -Raw
    if ($content -notmatch "telemetry-consumer") {
        $content = $content -replace "(\s+## Start the main shell)", "`n    display_msg `"Starting telemetry consumer ...`"`n    /scripts/telemetry-consumer-start.sh &`n`$1"
        $content += @"

/usr/bin/telemetry-consumer=telemetry-consumer

[perms=0755] /scripts/telemetry-consumer-start.sh = {
#!/bin/sh
telemetry-consumer 0x1c050000 38
}
"@
        Set-Content -LiteralPath $buildFile -Value $content
        Write-Host "Patched Guest B buildfile with telemetry consumer."
    }
}

Invoke-QnxCommand -QnxEnv $qnxEnvResolved -Command "make -C `"$appDir`" clean all install"
Invoke-QnxCommand -QnxEnv $qnxEnvResolved -Command "make -C `"$imageDir`" clean all"

Write-Host "Guest B IFS ready in $imageDir"
