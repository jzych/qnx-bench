param(
    [string]$WorkDir
)

. "$PSScriptRoot\..\..\tools\common.ps1"

if (-not $WorkDir) { $WorkDir = Join-RepoPath ".work" }

$repoRoot = Get-RepoRoot
$bspImages = Join-Path $WorkDir "bsp\rpi5-psb\images"
$makefile = Join-Path $bspImages "Makefile"
$commonBuild = Join-Path $bspImages "rpi5-common.build"
$overlay = Join-Path $repoRoot "default-image\overlays\rpi5-hypervisor.build"
$destBuild = Join-Path $bspImages "rpi5-hypervisor.build"

Resolve-RequiredPath -Path $bspImages -Description "Raspberry Pi 5 BSP images directory" | Out-Null
Resolve-RequiredPath -Path $makefile -Description "Raspberry Pi 5 BSP images Makefile" | Out-Null
Resolve-RequiredPath -Path $commonBuild -Description "Raspberry Pi 5 BSP common buildfile" | Out-Null
Resolve-RequiredPath -Path $overlay -Description "Host build overlay" | Out-Null

Copy-Item -LiteralPath $overlay -Destination $destBuild -Force
Write-Host "Applied host build overlay: $destBuild"

$commonContent = Get-Content -LiteralPath $commonBuild -Raw
$autoMountBlock = @"
    ############################################################################################
    ## qnx-bench GPT data layout automount
    ############################################################################################
    sh /scripts/auto_mount_gpt_layout.sh &

"@

$autoMountPattern = "(?m)\r?\n[ \t]*#{20,}\r?\n[ \t]*## qnx-bench GPT data layout automount\r?\n[ \t]*#{20,}\r?\n[ \t]*sh /scripts/auto_mount_gpt_layout\.sh &[ \t]*\r?\n"
$commonContent = [regex]::Replace($commonContent, $autoMountPattern, "`r`n")

if ($commonContent -match "(?m)^\s+/proc/boot/\.storage-server\.sh\s*$") {
    $commonContent = $commonContent -replace "(?m)^(\s+/proc/boot/\.storage-server\.sh\s*)$", "`$1`r`n`r`n$autoMountBlock"
    Set-Content -LiteralPath $commonBuild -Value $commonContent -Encoding ascii
    Write-Host "Added qnx-bench GPT automount startup hook."
} else {
    throw "Could not find storage-server startup line in $commonBuild"
}

$content = Get-Content -LiteralPath $makefile -Raw

$hypervisorTarget = @"

hypervisor: `$`(BOARD`)-hypervisor.build
	`$`(HOST_MKIFS`) -v -r`$`(INSTALL`) `$`(MKIFSFLAGS`) `$`^ ifs-`$`(BOARD`).bin
"@

$combinedTarget = @"

screen-remote-debug-wifi-hypervisor: `$`(BOARD`)-hypervisor.build
	`$`(HOST_MKIFS`) -v -r`$`(INSTALL`) `$`(MKIFSFLAGS`) -l "#define SCREEN_SUPPORT 1" -l "#define REMOTE_DEBUG 1" -l "#define WIFI_SUPPORT 1" `$`^ ifs-`$`(BOARD`).bin

"@

$legacyTargetsPattern = "(?ms)\r?\nhypervisor:\r?\n\tmkifs -vvv -r\.\./install -o ifs-rpi5\.bin rpi5-hypervisor\.build\r?\n\r?\nscreen-remote-debug-wifi-hypervisor: hypervisor\r?\n"
$content = [regex]::Replace($content, $legacyTargetsPattern, "`r`n")

$combinedBlockPattern = "(?ms)^screen-remote-debug-wifi-hypervisor:.*?(?=^\S[^:\r\n]*:|\z)"
$combinedMatch = [regex]::Match($content, $combinedBlockPattern)
if ($combinedMatch.Success -and (
        $combinedMatch.Value -notmatch "#define SCREEN_SUPPORT 1" -or
        $combinedMatch.Value -notmatch "#define REMOTE_DEBUG 1" -or
        $combinedMatch.Value -notmatch "#define WIFI_SUPPORT 1")) {
    $content = [regex]::Replace($content, $combinedBlockPattern, $combinedTarget)
    Write-Host "Repaired screen/remote-debug/wifi hypervisor Makefile target."
} elseif (-not $combinedMatch.Success) {
    $content = $content.TrimEnd() + $combinedTarget
    Write-Host "Added screen/remote-debug/wifi hypervisor Makefile target."
}

if ($content -notmatch "(?m)^hypervisor:\s") {
    $content = $content.TrimEnd() + $hypervisorTarget
    Write-Host "Added hypervisor Makefile target."
}

if ($content -notmatch "(?m)^\.PHONY:.*screen-remote-debug-wifi-hypervisor") {
    $content = $content -replace "(?m)^(\.PHONY:.*)$", "`$1 hypervisor screen-remote-debug-wifi-hypervisor"
    Write-Host "Updated .PHONY targets."
}

Set-Content -LiteralPath $makefile -Value $content -Encoding ascii

if ($content -match "(?m)^hypervisor:\s" -and
    $content -match "(?m)^screen-remote-debug-wifi-hypervisor:\s") {
    Write-Host "Hypervisor Makefile targets are present."
} else {
    throw "Failed to add required hypervisor Makefile targets to $makefile"
}
