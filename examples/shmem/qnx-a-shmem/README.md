# qnx-a-shmem

Guest A is the shared-memory telemetry producer.

It is based on the QNX generic ARM Hypervisor guest BSP. This directory stores
only the project-owned C++ telemetry source, build fragment, and helper scripts.
The guest BSP itself remains in `.work\bsp\hyp-guest-arm`.

## Build

Build only Guest A from the repository root:

```powershell
.\examples\shmem\qnx-a-shmem\scripts\build.ps1
```

Output:

```text
.work\bsp\hyp-guest-arm\images\guest-1\qnx800-guest-1.ifs
```

## Upload

Stage Guest A on the target:

```powershell
.\examples\shmem\qnx-a-shmem\scripts\upload.ps1 `
  -Target [ip-address] `
  -User qnxuser
```

Install it as root on the target:

```sh
su root
/scripts/mount_gpt_layout.sh || true
mkdir -p /qnx/system_a/guests/qnx-guest-1
cp /qnx/config/upload/qnx800-guest-1.ifs /qnx/system_a/guests/qnx-guest-1/qnx800-guest-1.ifs
sync
```

Use `examples/shmem/scripts/upload-all.ps1` for the normal two-guest flow.
