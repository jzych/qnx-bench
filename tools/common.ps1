Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:QnxBenchRepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Get-RepoRoot {
    return $script:QnxBenchRepoRoot
}

function Join-RepoPath {
    param([Parameter(Mandatory=$true)][string]$Path)
    return (Join-Path (Get-RepoRoot) $Path)
}

function Ensure-Directory {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Resolve-RequiredPath {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Description
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Description not found: $Path"
    }
    return (Resolve-Path -LiteralPath $Path).Path
}

function Get-QnxEnvPath {
    param([string]$QnxEnv)
    if ([string]::IsNullOrWhiteSpace($QnxEnv)) {
        $QnxEnv = $env:QNX_ENV
    }
    if ([string]::IsNullOrWhiteSpace($QnxEnv)) {
        throw "QNX environment batch file not specified. Set QNX_ENV or pass -QnxEnv."
    }
    return (Resolve-RequiredPath -Path $QnxEnv -Description "QNX environment batch file")
}

function Invoke-QnxCommand {
    param(
        [Parameter(Mandatory=$true)][string]$QnxEnv,
        [Parameter(Mandatory=$true)][string]$Command
    )
    $envPath = Get-QnxEnvPath -QnxEnv $QnxEnv
    cmd.exe /d /c "call `"$envPath`" && $Command"
    if ($LASTEXITCODE -ne 0) {
        throw "QNX command failed with exit code ${LASTEXITCODE}: $Command"
    }
}
