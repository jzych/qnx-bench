param(
    [string]$QnxEnv = $env:QNX_ENV,
    [string]$WorkDir,
    [string]$BootSource,
    [string]$OutputDir,
    [string]$ImageName = "rpi5-qnx8-hyp-gpt.img",
    [string]$HostIfs,
    [string]$Guest1Ifs,
    [string]$Guest2Ifs,
    [string]$Guest1Conf,
    [string]$Guest2Conf,
    [UInt64]$TotalSectors = 123596800
)

. "$PSScriptRoot\..\..\tools\common.ps1"

if (-not $WorkDir) { $WorkDir = Join-RepoPath ".work" }
if (-not $OutputDir) { $OutputDir = Join-RepoPath ".work\output\default-image" }

$qnxEnvResolved = Get-QnxEnvPath -QnxEnv $QnxEnv
$repoRoot = Get-RepoRoot
$bootSourceResolved = Resolve-RequiredPath -Path $BootSource -Description "boot source directory"

if (-not $HostIfs) { $HostIfs = Join-Path $WorkDir "bsp\rpi5-psb\images\ifs-rpi5.bin" }
if (-not $Guest1Ifs) { $Guest1Ifs = Join-Path $WorkDir "bsp\hyp-guest-arm\images\guest-1\qnx800-guest-aarch64-le.ifs" }
if (-not $Guest2Ifs) { $Guest2Ifs = Join-Path $WorkDir "bsp\hyp-guest-arm\images\guest-2\qnx800-guest-aarch64-le.ifs" }
if (-not $Guest1Conf) { $Guest1Conf = Join-Path $repoRoot "default-image\overlays\qvmtest\guest1-noblk.qvmconf" }
if (-not $Guest2Conf) { $Guest2Conf = Join-Path $repoRoot "default-image\overlays\qvmtest\guest2-noblk.qvmconf" }

Resolve-RequiredPath -Path $HostIfs -Description "host IFS" | Out-Null
Resolve-RequiredPath -Path $Guest1Ifs -Description "guest 1 IFS" | Out-Null
Resolve-RequiredPath -Path $Guest2Ifs -Description "guest 2 IFS" | Out-Null
Resolve-RequiredPath -Path $Guest1Conf -Description "guest 1 qvmconf" | Out-Null
Resolve-RequiredPath -Path $Guest2Conf -Description "guest 2 qvmconf" | Out-Null

function Reset-Directory {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Copy-Tree {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Destination
    )
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Get-ChildItem -LiteralPath $Source -Force | Where-Object {
        $_.Name -ne "System Volume Information"
    } | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
    }
}

$stage = Join-Path $OutputDir "staging"
$fsRoot = Join-Path $OutputDir "filesystems"
$bootStage = Join-Path $stage "boot"
$systemA = Join-Path $stage "system_a"
$systemB = Join-Path $stage "system_b"
$config = Join-Path $stage "config"
$var = Join-Path $stage "var"
$vmstore = Join-Path $stage "vmstore"
$dumps = Join-Path $stage "dumps"

Reset-Directory -Path $OutputDir
foreach ($dir in @($stage,$fsRoot,$bootStage,$systemA,$systemB,$config,$var,$vmstore,$dumps)) {
    Ensure-Directory -Path $dir
}

Copy-Tree -Source $bootSourceResolved -Destination $bootStage
Copy-Item -LiteralPath $HostIfs -Destination (Join-Path $bootStage "ifs-rpi5.bin") -Force

$guest1Dir = Join-Path $systemA "guests\qnx-guest-1"
$guest2Dir = Join-Path $systemB "guests\qnx-guest-2"
Ensure-Directory -Path $guest1Dir
Ensure-Directory -Path $guest2Dir
Ensure-Directory -Path (Join-Path $config "qvmtest")
Ensure-Directory -Path (Join-Path $var "log")
Ensure-Directory -Path (Join-Path $vmstore "guests")
Ensure-Directory -Path (Join-Path $dumps "crash")

Copy-Item -LiteralPath $Guest1Ifs -Destination (Join-Path $guest1Dir "qnx800-guest-1.ifs") -Force
Copy-Item -LiteralPath $Guest2Ifs -Destination (Join-Path $guest2Dir "qnx800-guest-2.ifs") -Force
Copy-Item -LiteralPath $Guest1Conf -Destination (Join-Path $guest1Dir "qnx800-guest-1.qvmconf") -Force
Copy-Item -LiteralPath $Guest2Conf -Destination (Join-Path $guest2Dir "qnx800-guest-2.qvmconf") -Force
Copy-Tree -Source (Join-Path $repoRoot "default-image\overlays\qvmtest") -Destination (Join-Path $config "qvmtest")

"system_a: guest-1 baseline artifacts" | Set-Content -LiteralPath (Join-Path $systemA "README.txt") -Encoding ascii
"system_b: guest-2 baseline artifacts" | Set-Content -LiteralPath (Join-Path $systemB "README.txt") -Encoding ascii
"reserved persistent config partition" | Set-Content -LiteralPath (Join-Path $config "README.txt") -Encoding ascii
"reserved persistent var partition" | Set-Content -LiteralPath (Join-Path $var "README.txt") -Encoding ascii
"reserved vmstore partition" | Set-Content -LiteralPath (Join-Path $vmstore "README.txt") -Encoding ascii
"reserved dumps partition" | Set-Content -LiteralPath (Join-Path $dumps "README.txt") -Encoding ascii

$sectorSize = 512
$bootSectors = 1048576
$systemSectors = 4194304
$configSectors = 2097152
$varSectors = 8388608
$vmstoreSectors = 100663296
$alignmentSectors = 2048
$reservedGptSectors = 34
$usedBeforeDumps = $alignmentSectors + $bootSectors + (2 * $systemSectors) + $configSectors + $varSectors + $vmstoreSectors
$dumpsSectors = $TotalSectors - $usedBeforeDumps - $reservedGptSectors
if ($dumpsSectors -lt $alignmentSectors) {
    throw "TotalSectors=$TotalSectors leaves no useful p7 dumps/reserved partition."
}

$bootImg = Join-Path $fsRoot "boot.fat32.img"
$systemAImg = Join-Path $fsRoot "system_a.qnx6.img"
$systemBImg = Join-Path $fsRoot "system_b.qnx6.img"
$configImg = Join-Path $fsRoot "config.qnx6.img"
$varImg = Join-Path $fsRoot "var.qnx6.img"
$vmstoreImg = Join-Path $fsRoot "vmstore.qnx6.img"
$dumpsImg = Join-Path $fsRoot "dumps.qnx6.img"
$diskCfg = Join-Path $OutputDir "rpi5-gpt.diskimage.cfg"
$diskImg = Join-Path $OutputDir $ImageName

$bootStageQnx = $bootStage.Replace("\", "/")
$systemAQnx = $systemA.Replace("\", "/")
$systemBQnx = $systemB.Replace("\", "/")
$configQnx = $config.Replace("\", "/")
$varQnx = $var.Replace("\", "/")
$vmstoreQnx = $vmstore.Replace("\", "/")
$dumpsQnx = $dumps.Replace("\", "/")
$bootImgQnx = $bootImg.Replace("\", "/")
$systemAImgQnx = $systemAImg.Replace("\", "/")
$systemBImgQnx = $systemBImg.Replace("\", "/")
$configImgQnx = $configImg.Replace("\", "/")
$varImgQnx = $varImg.Replace("\", "/")
$vmstoreImgQnx = $vmstoreImg.Replace("\", "/")
$dumpsImgQnx = $dumpsImg.Replace("\", "/")

Invoke-QnxCommand -QnxEnv $qnxEnvResolved -Command "mkfatfsimg -l `"[num_sectors=$bootSectors]`" -l `"[fat=32]`" `"$bootStageQnx`" `"$bootImgQnx`""
Invoke-QnxCommand -QnxEnv $qnxEnvResolved -Command "mkqnx6fsimg -l `"[num_sectors=$systemSectors]`" -l `"[max_sectors=$systemSectors]`" `"$systemAQnx`" `"$systemAImgQnx`""
Invoke-QnxCommand -QnxEnv $qnxEnvResolved -Command "mkqnx6fsimg -l `"[num_sectors=$systemSectors]`" -l `"[max_sectors=$systemSectors]`" `"$systemBQnx`" `"$systemBImgQnx`""
Invoke-QnxCommand -QnxEnv $qnxEnvResolved -Command "mkqnx6fsimg -l `"[num_sectors=$configSectors]`" -l `"[max_sectors=$configSectors]`" `"$configQnx`" `"$configImgQnx`""
Invoke-QnxCommand -QnxEnv $qnxEnvResolved -Command "mkqnx6fsimg -l `"[num_sectors=$varSectors]`" -l `"[max_sectors=$varSectors]`" `"$varQnx`" `"$varImgQnx`""
Invoke-QnxCommand -QnxEnv $qnxEnvResolved -Command "mkqnx6fsimg -l `"[num_sectors=$vmstoreSectors]`" -l `"[max_sectors=$vmstoreSectors]`" `"$vmstoreQnx`" `"$vmstoreImgQnx`""
Invoke-QnxCommand -QnxEnv $qnxEnvResolved -Command "mkqnx6fsimg -l `"[num_sectors=$dumpsSectors]`" -l `"[max_sectors=$dumpsSectors]`" `"$dumpsQnx`" `"$dumpsImgQnx`""

$cfg = @"
[cylinders=64k heads=32 sectors_per_track=16]
[num_sectors=$TotalSectors]
[align=$alignmentSectors]

[partition=1
  type_guid="ms"
  name="boot"
  num_sectors=$bootSectors
  boot=true
] "filesystems/boot.fat32.img"

[partition=2
  type_guid="qnx6"
  name="system_a"
  num_sectors=$systemSectors
] "filesystems/system_a.qnx6.img"

[partition=3
  type_guid="qnx6"
  name="system_b"
  num_sectors=$systemSectors
] "filesystems/system_b.qnx6.img"

[partition=4
  type_guid="qnx6"
  name="config"
  num_sectors=$configSectors
] "filesystems/config.qnx6.img"

[partition=5
  type_guid="qnx6"
  name="var"
  num_sectors=$varSectors
] "filesystems/var.qnx6.img"

[partition=6
  type_guid="qnx6"
  name="vmstore"
  num_sectors=$vmstoreSectors
] "filesystems/vmstore.qnx6.img"

[partition=7
  type_guid="qnx6"
  name="dumps"
  num_sectors=$dumpsSectors
] "filesystems/dumps.qnx6.img"
"@
$cfg | Set-Content -LiteralPath $diskCfg -Encoding ascii

$layout = @{
    totalSectors = $TotalSectors
    sectorSize = $sectorSize
    partitions = @(
        @{ name = "boot"; sizeSectors = $bootSectors; image = $bootImg },
        @{ name = "system_a"; sizeSectors = $systemSectors; image = $systemAImg },
        @{ name = "system_b"; sizeSectors = $systemSectors; image = $systemBImg },
        @{ name = "config"; sizeSectors = $configSectors; image = $configImg },
        @{ name = "var"; sizeSectors = $varSectors; image = $varImg },
        @{ name = "vmstore"; sizeSectors = $vmstoreSectors; image = $vmstoreImg },
        @{ name = "dumps"; sizeSectors = $dumpsSectors; image = $dumpsImg }
    )
}
$layout | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $OutputDir "layout.json")

Push-Location $OutputDir
try {
    Invoke-QnxCommand -QnxEnv $qnxEnvResolved -Command "diskimage -g -S -z -c `"rpi5-gpt.diskimage.cfg`" -o `"$ImageName`""
} finally {
    Pop-Location
}

Resolve-RequiredPath -Path $diskImg -Description "GPT disk image" | Out-Null
Write-Host "GPT image ready: $diskImg"
