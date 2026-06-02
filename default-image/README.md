# Default Image

This directory contains the host image overlay and GPT image assembly scripts.

The default image preserves the fixed partition layout and provides a minimal
Hypervisor-capable host. Guest operating systems are not autostarted.

## Build

Run from the repository root in PowerShell.

```powershell
# Use the local QNX SDP environment batch file.
$env:QNX_ENV = "X:\YOUR\PATH\TO\qnx800\qnxsdp-env.bat"

# Copy external BSP workspaces into ignored .work\bsp\.
.\default-image\scripts\bootstrap-workspace.ps1 `
  -Rpi5BspSource M:\CodingProjects\qnxprojects\bsp\rpi5-psb `
  -HypGuestBspSource M:\CodingProjects\qnxprojects\bsp\hyp-guest-arm

# Build both shmem guest IFS files for the data partitions.
.\examples\shmem\scripts\build-all.ps1

# Build the Raspberry Pi 5 host IFS and assemble the GPT image.
.\default-image\build-default-image.ps1 `
  -BootSource M:\CodingProjects\qnxprojects\targets\rpi5-boot-source

# Check the generated image layout.
.\default-image\scripts\verify-image-layout.ps1 `
  -OutputDir .work\output\default-image
```

The required host output name remains `ifs-rpi5.bin` inside the copied BSP build
workspace. The final GPT image is generated under `.work\output\default-image\`.

The host IFS embeds the `/qnx` and `/vmstore` mountpoints used by the fixed GPT
layout. At boot, `/scripts/auto_mount_gpt_layout.sh` waits for
`/dev/sd0.qnx6.6` and retries `/scripts/mount_gpt_layout.sh` until the data
layout is mounted. The manual helper is still safe to run again as root. It
prepares `/qnx/config/upload` for `qnxuser` uploads and makes qvmtest shell
helpers executable.

## Booted Target Check

After flashing and booting the image, verify the mounted data layout and manual
guest launcher:

```sh
ls -ld /qnx/system_a /qnx/system_b /qnx/config /qnx/var /vmstore /qnx/dumps
ls -l /qnx/config/qvmtest/start-qvm-minimal-verify.sh
cat /dev/shmem/mount_gpt_layout.log
```
