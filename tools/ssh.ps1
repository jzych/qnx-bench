param(
    [string]$Target = "192.168.0.31",
    [string]$User = "qnxuser",
    [string]$Command
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Command)) {
    ssh "$User@$Target"
} else {
    ssh "$User@$Target" $Command
}
