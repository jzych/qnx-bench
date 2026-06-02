# Shared Memory Example

Two QNX generic ARM Hypervisor guests exchange telemetry through a host
configured shared-memory vdev.

- `qnx-a-shmem` builds Guest A, the telemetry producer.
- `qnx-b-shmem` builds Guest B, the telemetry consumer.

The guests are copied to the target data partitions and started manually.

See [docs/runbook.md](docs/runbook.md) for the full build, upload, run, and
verification flow.

## Minimal Flow

Build both guests from the repository root:

```powershell
.\examples\shmem\scripts\build-all.ps1
```

Upload the guest IFS files and install helper:

```powershell
.\examples\shmem\scripts\upload-all.ps1 -Target [ip-address] -User qnxuser
```

Install, run, and verify on the target:

```sh
su root
sh /qnx/config/upload/install-shmem-guests.sh
/qnx/config/qvmtest/start-qvm-minimal-verify.sh
pidin ar | grep qvm
grep telemetry /dev/shmem/guest1-min.log
grep telemetry /dev/shmem/guest2-min.log
```

If `/qnx/config/upload` is missing, check `/dev/shmem/mount_gpt_layout.log` and
run `/scripts/mount_gpt_layout.sh` as root.
