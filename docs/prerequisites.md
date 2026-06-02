# Prerequisites

Install or extract these locally before building:

- QNX SDP 8.0.
- QNX Hypervisor package for QNX 8.0.
- Raspberry Pi 5 BSP already validated for this bench.
- QNX generic ARM Hypervisor guest BSP.
- Raspberry Pi boot partition payload from the known-good BSP build.
- Windows PowerShell.
- QNX command-line tools available through the SDP environment batch file.

The scripts default to the repository-local `.work/` directory for copied BSP
workspaces and generated output. The original QNX installation and extracted BSP
directories should stay outside git.

## Environment

Set `QNX_ENV` or pass `-QnxEnv` to scripts:

```powershell
$env:QNX_ENV = "X:\YOUR\PATH\TO\qnx800\qnxsdp-env.bat"
```

Verify the environment path exists before starting a build:

```powershell
Test-Path $env:QNX_ENV
```

## Boot Payload

Pass the Raspberry Pi FAT boot partition payload directory to
`-BootSource`. On the current bench host this has been:

```powershell
M:\CodingProjects\qnxprojects\targets\rpi5-boot-source
```

The boot payload is an external local input and must stay outside git.

## Workspace Bootstrap

Copy local BSP workspaces into ignored `.work\bsp\`:

```powershell
.\default-image\scripts\bootstrap-workspace.ps1 `
  -Rpi5BspSource M:\CodingProjects\qnxprojects\bsp\rpi5-psb `
  -HypGuestBspSource M:\CodingProjects\qnxprojects\bsp\hyp-guest-arm
```

This copies local BSP workspaces into `.work\bsp\`. That directory is ignored by
git.

Verify the copied workspaces exist:

```powershell
Test-Path .work\bsp\rpi5-psb
Test-Path .work\bsp\hyp-guest-arm
```
