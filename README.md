# qnx-bench

Raspberry Pi 5 QNX 8.0 bench image and its Hypervisor examples.

Build a default Raspberry Pi 5 QNX host image with the concrete GPT layout used
by the bench, minimal automatic startup, and manual Hypervisor guest startup
helpers.

The default image:

- Boots QNX 8.0 on Raspberry Pi 5.
- Starts networking, SSH, qconn, pdebug, devc-pty and Screen.
- Starts QNX Hypervisor support on the host.
- Mounts the GPT data layout automatically.
- Does not autostart guest operating systems.
- Partition layout documented in [docs/partition-layout.md](docs/partition-layout.md).

## Repository Layout

- `default-image/` - host image overlay and GPT image build scripts.
- `examples/` - guest os examples.
- `docs/` - setup, partition layout, current status, and troubleshooting.
- `tools/` - helper scripts for QNX environment, SSH, and checks.

## Local Inputs

You need these local inputs installed or extracted outside this repository:

- QNX SDP 8.0.
- QNX Hypervisor package.
- Raspberry Pi 5 BSP for QNX SDP 9.0/8.0-compatible workflow already used by
  this bench.
- QNX generic ARM Hypervisor guest BSP.
- Raspberry Pi boot partition payload files from the working BSP output.

See [docs/prerequisites.md](docs/prerequisites.md).

## Quick Start

Run from the repository root in PowerShell:

```powershell
$env:QNX_ENV = "X:\YOUR\PATH\TO\qnx800\qnxsdp-env.bat"

# Copy external BSP workspaces into ignored .work\bsp\.
.\default-image\scripts\bootstrap-workspace.ps1 `
  -Rpi5BspSource M:\CodingProjects\qnxprojects\bsp\rpi5-psb `
  -HypGuestBspSource M:\CodingProjects\qnxprojects\bsp\hyp-guest-arm

# Build the host IFS and assemble the GPT SD-card image.
.\default-image\build-default-image.ps1 `
  -BootSource M:\CodingProjects\qnxprojects\targets\rpi5-boot-source

# Verify generated partition sizes against layout.json.
.\default-image\scripts\verify-image-layout.ps1 `
  -OutputDir .work\output\default-image
```

The generated image is written under `.work\output\default-image\` and is
ignored by git.

## Target Access

The current bench target normally uses:

```powershell
ssh qnxuser@192.168.0.31
```

Default password used by the current image is `qnxuser`. Root elevation has used
`su` with password `root` on the bench image.

## Manual Guest Startup

After boot, connect over SSH and run:

```sh
su root
/qnx/config/qvmtest/start-qvm-minimal-verify.sh
pidin ar | grep qvm
grep telemetry /dev/shmem/guest1-min.log
grep telemetry /dev/shmem/guest2-min.log
```

If `/qnx/config/qvmtest` is missing, check `/dev/shmem/mount_gpt_layout.log`
and run `/scripts/mount_gpt_layout.sh` as root to retry the data partition
mounts.

The shared-memory example runbook is
[examples/shmem/docs/runbook.md](examples/shmem/docs/runbook.md).
