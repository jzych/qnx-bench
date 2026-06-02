# qnx-b-shmem

Guest B is the shared-memory telemetry consumer.

It is based on the QNX generic ARM Hypervisor guest BSP. This directory stores
only the project-owned C++ telemetry source, build fragment, and helper scripts.
The guest BSP itself remains in `.work\bsp\hyp-guest-arm`.

## Build

Build only Guest B from the repository root:

```powershell
.\examples\shmem\qnx-b-shmem\scripts\build.ps1
```

Output:

```text
.work\bsp\hyp-guest-arm\images\guest-2\qnx800-guest-2.ifs
```

## Upload

Stage Guest B on the target:

```powershell
.\examples\shmem\qnx-b-shmem\scripts\upload.ps1 `
  -Target 192.168.0.31 `
  -User qnxuser
```

Install it as root on the target:

```sh
su root
/scripts/mount_gpt_layout.sh || true
mkdir -p /qnx/system_b/guests/qnx-guest-2
cp /qnx/config/upload/qnx800-guest-2.ifs /qnx/system_b/guests/qnx-guest-2/qnx800-guest-2.ifs
sync
```

Use `examples/shmem/scripts/upload-all.ps1` for the normal two-guest flow.
