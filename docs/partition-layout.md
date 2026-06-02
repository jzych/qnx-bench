# Partition Layout

The partition layout is concrete for the current bench and must not be changed
without an explicit migration decision.

| Partition | Size | Type | Mount/Purpose |
| --- | ---: | --- | --- |
| p1 | 512 MiB | FAT32 | `/boot` |
| p2 | 2 GiB | QNX6 | `/qnx/system_a` |
| p3 | 2 GiB | QNX6 | `/qnx/system_b` |
| p4 | 1 GiB | QNX6 | `/qnx/config` |
| p5 | 4 GiB | QNX6 | `/qnx/var` |
| p6 | 48 GiB | QNX6 | `/vmstore` |
| p7 | rest | QNX6/raw | `/qnx/dumps` or reserved |

The generated QNX6 filesystem images should be created at full partition size,
not as small files that need `chkqnx6fs -x` on first boot.

The host IFS must include the mountpoint directories for `/qnx/system_a`,
`/qnx/system_b`, `/qnx/config`, `/qnx/var`, `/qnx/dumps`, and `/vmstore`.
The startup hook `/scripts/auto_mount_gpt_layout.sh` waits for
`/dev/sd0.qnx6.6` and retries `/scripts/mount_gpt_layout.sh` automatically at
boot. The manual helper mounts the target-visible Raspberry Pi devices
`/dev/sd0.qnx6.1` through `/dev/sd0.qnx6.6`.

Current default staging:

- Guest 1 IFS and qvmconf are staged under `/qnx/system_a/guests/qnx-guest-1/`.
- Guest 2 IFS and qvmconf are staged under `/qnx/system_b/guests/qnx-guest-2/`.
- Manual qvm test scripts and qvmconfs are staged under `/qnx/config/qvmtest/`.
- `/vmstore` is reserved for later guest storage.

Verify the generated image layout on the host:

```powershell
.\default-image\scripts\verify-image-layout.ps1 `
  -OutputDir .work\output\default-image
```

Verify the booted target layout:

```sh
mount
cat /dev/shmem/mount_gpt_layout.log
```
