param(
    [string]$QnxEnv = $env:QNX_ENV,
    [string]$WorkDir
)

. "$PSScriptRoot\..\..\..\..\tools\common.ps1"

if (-not $WorkDir) { $WorkDir = Join-RepoPath ".work" }

function Resolve-BuildFile {
    param(
        [Parameter(Mandatory=$true)][string]$ImageDir,
        [Parameter(Mandatory=$true)][string[]]$Names
    )

    foreach ($name in $Names) {
        $candidate = Join-Path $ImageDir $name
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    throw "guest image buildfile not found in ${ImageDir}: $($Names -join ', ')"
}

function Remove-ProjectBlocks {
    param([Parameter(Mandatory=$true)][string]$Content)
    return [regex]::Replace(
        $Content,
        "(?ms)\r?\n?# BEGIN qnx-bench virtio-net-(udp|tcp) .*?# END qnx-bench virtio-net-(udp|tcp)\r?\n?",
        "`n")
}

function Remove-LegacyTelemetryBlocks {
    param([Parameter(Mandatory=$true)][string]$Content)

    $updated = [regex]::Replace(
        $Content,
        '(?m)^\s*display_msg "Starting telemetry (producer|consumer) \.\.\."\r?\n\s*/scripts/telemetry-(producer|consumer)-start\.sh &\r?\n',
        "")

    foreach ($app in @(
        "telemetry-producer",
        "telemetry-consumer",
        "net-telemetry-client",
        "net-telemetry-server",
        "udp-telemetry-client",
        "udp-telemetry-server"
    )) {
        $escaped = [regex]::Escape($app)
        $updated = [regex]::Replace(
            $updated,
            "(?m)^\s*# Guest [12] telemetry (producer|consumer)\r?\n/usr/bin/$escaped=$escaped\r?\n",
            "")
        $updated = [regex]::Replace(
            $updated,
            "(?m)^/usr/bin/$escaped=$escaped\r?\n",
            "")
        $updated = [regex]::Replace(
            $updated,
            "(?ms)\r?\n\[perms=0755\] /scripts/$escaped-start\.sh = \{\r?\n.*?\r?\n\}\r?\n?",
            "`n")
    }

    return $updated
}

$qnxEnvResolved = Get-QnxEnvPath -QnxEnv $QnxEnv
$guestRoot = Resolve-RequiredPath -Path (Join-Path $WorkDir "bsp\hyp-guest-arm") -Description "Hypervisor guest BSP workspace"
$demosDir = Resolve-RequiredPath -Path (Join-Path $guestRoot "src\apps\hypervisor\demos") -Description "guest demo app directory"
$appDir = Join-Path $demosDir "udp-telemetry-client"
$appLeafDir = Join-Path $appDir "nto-aarch64-le"
$imageDir = Resolve-RequiredPath -Path (Join-Path $guestRoot "images\guest-1") -Description "guest 1 image directory"
$buildFile = Resolve-BuildFile -ImageDir $imageDir -Names @("qnx800-guest-1.build", "qnx800-guest-a.build")

Ensure-Directory -Path $appDir
Ensure-Directory -Path $appLeafDir
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "..\app\Makefile") -Destination (Join-Path $appDir "Makefile") -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "..\app\common.mk") -Destination (Join-Path $appDir "common.mk") -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "..\app\udp-telemetry-client.use") -Destination (Join-Path $appDir "udp-telemetry-client.use") -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "..\src\udp-telemetry-client.cpp") -Destination (Join-Path $appDir "udp-telemetry-client.cpp") -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "..\app\nto-aarch64-le\Makefile") -Destination (Join-Path $appLeafDir "Makefile") -Force

$content = Get-Content -LiteralPath $buildFile -Raw
$content = Remove-ProjectBlocks -Content $content
$content = Remove-LegacyTelemetryBlocks -Content $content

$startBlock = @'
    # BEGIN qnx-bench virtio-net-udp start
    display_msg "Starting virtio-net UDP telemetry client ..."
    /scripts/udp-telemetry-client-start.sh &
    # END qnx-bench virtio-net-udp
'@

if ($content -notmatch "## Start the main shell") {
    throw "Could not find shell start marker in $buildFile"
}
$content = $content -replace "(\r?\n\s+## Start the main shell)", "`n$startBlock`$1"

$fileBlock = @'

# BEGIN qnx-bench virtio-net-udp files
/usr/bin/udp-telemetry-client=udp-telemetry-client

[perms=0755] /scripts/udp-telemetry-client-start.sh = {
#!/bin/sh
set -u

NET_IF=""
tries=0
while [ "$tries" -lt 20 ]; do
    if ifconfig vtnet1 >/dev/null 2>&1; then
        NET_IF=vtnet1
        break
    fi
    if ifconfig vtnet0 >/dev/null 2>&1; then
        NET_IF=vtnet0
        break
    fi
    tries=`expr "$tries" + 1`
    sleep 1
done

if [ -z "$NET_IF" ]; then
    echo "udp-telemetry-client: no vtnet interface found"
else
    ifconfig "$NET_IF" 192.168.10.1/24 up || true
    echo "udp-telemetry-client: configured $NET_IF 192.168.10.1/24"
fi

exec udp-telemetry-client 192.168.10.2 5002 1000
}
# END qnx-bench virtio-net-udp
'@

$content += $fileBlock
if ($content -notmatch "/lib/libsocket\.so") {
    $content += "`n/lib/libsocket.so=libsocket.so`n"
}

Set-Content -LiteralPath $buildFile -Value $content -Encoding ascii
Write-Host "Patched Guest A buildfile with virtio-net UDP telemetry client."

Invoke-QnxCommand -QnxEnv $qnxEnvResolved -Command "make -C `"$appDir`" clean all install"
Invoke-QnxCommand -QnxEnv $qnxEnvResolved -Command "make -C `"$imageDir`" clean all"

$ifs = Join-Path $imageDir "qnx800-guest-1.ifs"
$exampleIfs = Join-Path $imageDir "qnx800-guest-1-virtio-net-udp.ifs"
Resolve-RequiredPath -Path $ifs -Description "guest 1 IFS" | Out-Null
Copy-Item -LiteralPath $ifs -Destination $exampleIfs -Force

Write-Host "Guest A virtio-net UDP IFS ready: $exampleIfs"
