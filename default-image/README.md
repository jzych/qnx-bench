# Default Image

This directory contains the host image overlay and GPT image assembly scripts.

The default image preserves the fixed partition layout and provides a minimal
Hypervisor-capable host. Guest operating systems are not autostarted.

## Build

```powershell
.\default-image\scripts\bootstrap-workspace.ps1 `
  -Rpi5BspSource M:\CodingProjects\qnxprojects\bsp\rpi5-psb `
  -HypGuestBspSource M:\CodingProjects\qnxprojects\bsp\hyp-guest-arm

.\examples\shmem\scripts\build-all.ps1

.\default-image\build-default-image.ps1 `
  -BootSource M:\CodingProjects\qnxprojects\bsp\rpi5-boot-source
```

The required host output name remains `ifs-rpi5.bin` inside the copied BSP build
workspace. The final GPT image is generated under `.work\output\default-image\`.
