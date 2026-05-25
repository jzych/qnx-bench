param(
    [string]$WorkDir
)

. "$PSScriptRoot\..\..\tools\common.ps1"

if (-not $WorkDir) { $WorkDir = Join-RepoPath ".work" }

$repoRoot = Get-RepoRoot
$bspImages = Join-Path $WorkDir "bsp\rpi5-psb\images"
$makefile = Join-Path $bspImages "Makefile"
$overlay = Join-Path $repoRoot "default-image\overlays\rpi5-hypervisor.build"
$destBuild = Join-Path $bspImages "rpi5-hypervisor.build"

Resolve-RequiredPath -Path $bspImages -Description "Raspberry Pi 5 BSP images directory" | Out-Null
Resolve-RequiredPath -Path $makefile -Description "Raspberry Pi 5 BSP images Makefile" | Out-Null
Resolve-RequiredPath -Path $overlay -Description "Host build overlay" | Out-Null

Copy-Item -LiteralPath $overlay -Destination $destBuild -Force
Write-Host "Applied host build overlay: $destBuild"

$content = Get-Content -LiteralPath $makefile -Raw

if ($content -notmatch "rpi5-hypervisor\.build") {
    $addition = @"

hypervisor:
	mkifs -vvv -r../install -o ifs-rpi5.bin rpi5-hypervisor.build

screen-remote-debug-wifi-hypervisor: hypervisor

"@
    Add-Content -LiteralPath $makefile -Value $addition
    Write-Host "Added hypervisor Makefile targets."
} else {
    Write-Host "Hypervisor Makefile targets already present."
}
