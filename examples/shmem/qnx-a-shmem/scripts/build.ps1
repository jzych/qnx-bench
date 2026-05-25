param(
    [string]$QnxEnv = $env:QNX_ENV,
    [string]$WorkDir
)

. "$PSScriptRoot\..\..\..\..\tools\common.ps1"

if (-not $WorkDir) { $WorkDir = Join-RepoPath ".work" }

$qnxEnvResolved = Get-QnxEnvPath -QnxEnv $QnxEnv
$guestRoot = Resolve-RequiredPath -Path (Join-Path $WorkDir "bsp\hyp-guest-arm") -Description "Hypervisor guest BSP workspace"
$appDir = Join-Path $guestRoot "src\apps\hypervisor\demos\telemetry-producer"
$imageDir = Join-Path $guestRoot "images\guest-1"
$buildFile = Join-Path $imageDir "qnx800-guest-a.build"

Resolve-RequiredPath -Path $appDir -Description "producer app directory" | Out-Null
Resolve-RequiredPath -Path $imageDir -Description "guest 1 image directory" | Out-Null

Copy-Item -LiteralPath (Join-Path $PSScriptRoot "..\src\telemetry-producer.cpp") -Destination (Join-Path $appDir "telemetry-producer.cpp") -Force
$oldC = Join-Path $appDir "telemetry-producer.c"
if (Test-Path -LiteralPath $oldC) { Remove-Item -LiteralPath $oldC -Force }

if (Test-Path -LiteralPath $buildFile) {
    $content = Get-Content -LiteralPath $buildFile -Raw
    if ($content -notmatch "telemetry-producer") {
        $content = $content -replace "(\s+## Start the main shell)", "`n    display_msg `"Starting telemetry producer ...`"`n    /scripts/telemetry-producer-start.sh &`n`$1"
        $content += @"

/usr/bin/telemetry-producer=telemetry-producer

[perms=0755] /scripts/telemetry-producer-start.sh = {
#!/bin/sh
telemetry-producer 0x1c050000 1000
}
"@
        Set-Content -LiteralPath $buildFile -Value $content
        Write-Host "Patched Guest A buildfile with telemetry producer."
    }
}

Invoke-QnxCommand -QnxEnv $qnxEnvResolved -Command "make -C `"$appDir`" clean all install"
Invoke-QnxCommand -QnxEnv $qnxEnvResolved -Command "make -C `"$imageDir`" clean all"

Write-Host "Guest A IFS ready in $imageDir"
