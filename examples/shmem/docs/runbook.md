# Shared Memory Runbook

## Build

From the repository root:

```powershell
.\examples\shmem\scripts\build-all.ps1
```

The script expects the QNX generic ARM Hypervisor guest BSP workspace at
`.work\bsp\hyp-guest-arm`. Create it first with:

```powershell
.\default-image\scripts\bootstrap-workspace.ps1 `
  -HypGuestBspSource M:\CodingProjects\qnxprojects\bsp\hyp-guest-arm
```

## Upload

```powershell
.\examples\shmem\scripts\upload-all.ps1 -Target 192.168.0.31
```

The script uses `scp` and `ssh`; enter target passwords interactively unless you
use your own SSH key setup. It stages these files on the target:

- `/qnx/config/upload/qnx800-guest-1.ifs`
- `/qnx/config/upload/qnx800-guest-2.ifs`
- `/qnx/config/upload/install-shmem-guests.sh`

## Install Into Persistent Partitions

The qvm configs expect the guest images at these exact paths:

- `/qnx/system_a/guests/qnx-guest-1/qnx800-guest-1.ifs`
- `/qnx/system_b/guests/qnx-guest-2/qnx800-guest-2.ifs`

After upload, connect to the target and install the staged images:

```sh
su root
sh /qnx/config/upload/install-shmem-guests.sh
```

Manual equivalent:

```sh
su root
/scripts/mount_gpt_layout.sh || true
mkdir -p /qnx/system_a/guests/qnx-guest-1 /qnx/system_b/guests/qnx-guest-2
cp /qnx/config/upload/qnx800-guest-1.ifs /qnx/system_a/guests/qnx-guest-1/qnx800-guest-1.ifs
cp /qnx/config/upload/qnx800-guest-2.ifs /qnx/system_b/guests/qnx-guest-2/qnx800-guest-2.ifs
chmod 0644 /qnx/system_a/guests/qnx-guest-1/qnx800-guest-1.ifs /qnx/system_b/guests/qnx-guest-2/qnx800-guest-2.ifs
sync
```

## Run On Target

```sh
su root
/qnx/config/qvmtest/start-qvm-minimal-verify.sh
```

## Verify

```sh
pidin ar | grep qvm
grep telemetry /dev/shmem/guest1-min.log
grep telemetry /dev/shmem/guest2-min.log
ls -la /dev/qvm /dev/vdevpeers
```

Expected evidence:

- Two `qvm` processes are running.
- `/dev/qvm/qnx-guest-1` and `/dev/qvm/qnx-guest-2` exist.
- Telemetry lines show messages produced by Guest A and consumed by Guest B.
