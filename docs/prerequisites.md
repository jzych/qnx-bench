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
$env:QNX_ENV = "C:\Users\jzych\qnx800\qnxsdp-env.bat"
```

## Workspace Bootstrap

```powershell
.\default-image\scripts\bootstrap-workspace.ps1 `
  -Rpi5BspSource M:\CodingProjects\qnxprojects\bsp\rpi5-psb `
  -HypGuestBspSource M:\CodingProjects\qnxprojects\bsp\hyp-guest-arm
```

This copies local BSP workspaces into `.work\bsp\`. That directory is ignored by
git.
