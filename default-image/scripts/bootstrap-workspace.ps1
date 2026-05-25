param(
    [string]$Rpi5BspSource,
    [string]$HypGuestBspSource,
    [string]$WorkDir,
    [switch]$Force
)

. "$PSScriptRoot\..\..\tools\common.ps1"

if (-not $WorkDir) { $WorkDir = Join-RepoPath ".work" }

$bspDir = Join-Path $WorkDir "bsp"
Ensure-Directory -Path $bspDir

function Copy-Workspace {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Destination,
        [Parameter(Mandatory=$true)][string]$Name
    )

    $resolvedSource = Resolve-RequiredPath -Path $Source -Description "$Name source"
    if ((Test-Path -LiteralPath $Destination) -and -not $Force) {
        Write-Host "$Name workspace already exists: $Destination"
        return
    }
    if (Test-Path -LiteralPath $Destination) {
        Remove-Item -LiteralPath $Destination -Recurse -Force
    }
    Write-Host "Copying $Name workspace to $Destination"
    Copy-Item -LiteralPath $resolvedSource -Destination $Destination -Recurse
}

if ($Rpi5BspSource) {
    Copy-Workspace -Source $Rpi5BspSource -Destination (Join-Path $bspDir "rpi5-psb") -Name "Raspberry Pi 5 BSP"
}

if ($HypGuestBspSource) {
    Copy-Workspace -Source $HypGuestBspSource -Destination (Join-Path $bspDir "hyp-guest-arm") -Name "Hypervisor guest BSP"
}

Write-Host "Workspace bootstrap complete: $WorkDir"
