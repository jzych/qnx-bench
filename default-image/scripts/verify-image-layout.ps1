param(
    [string]$OutputDir
)

. "$PSScriptRoot\..\..\tools\common.ps1"

if (-not $OutputDir) { $OutputDir = Join-RepoPath ".work\output\default-image" }

$layoutPath = Resolve-RequiredPath -Path (Join-Path $OutputDir "layout.json") -Description "layout manifest"
$layout = Get-Content -LiteralPath $layoutPath -Raw | ConvertFrom-Json

foreach ($partition in $layout.partitions) {
    Resolve-RequiredPath -Path $partition.image -Description "$($partition.name) image" | Out-Null
    $actualSectors = [math]::Floor((Get-Item -LiteralPath $partition.image).Length / $layout.sectorSize)
    if ($actualSectors -ne [Int64]$partition.sizeSectors) {
        throw "$($partition.name) has $actualSectors sectors, expected $($partition.sizeSectors)."
    }
    Write-Host "$($partition.name): $actualSectors sectors"
}

Write-Host "Layout image sizes match layout.json."
