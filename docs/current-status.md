# Current Project Status

## Host

- Raspberry Pi 5 boots QNX 8.0.
- SSH access works on the bench network.
- Screen starts on HDMI0 when a display is connected.
- qconn, pdebug, and devc-pty are included for remote development/debugging.
- Hypervisor host support is included in the current booting image.
- The host IFS includes GPT mountpoints and runs
  `/scripts/auto_mount_gpt_layout.sh` at boot.
- `/scripts/mount_gpt_layout.sh` remains available for manual repair.
- Guest autostart is intentionally disabled.

Verify the host state on a booted target:

```sh
pidin ar | grep -E 'io-pkt|sshd|qconn|screen|qvm'
ls -ld /qnx /vmstore
cat /dev/shmem/mount_gpt_layout.log
```

## Hypervisor Guests

The active example is `examples/shmem`.

- Guest A: QNX 8.0 generic ARM Hypervisor guest, telemetry producer.
- Guest B: QNX 8.0 generic ARM Hypervisor guest, telemetry consumer.
- Both guests are launched manually with qvm.
- The shmem guest build outputs are `qnx800-guest-1.ifs` and
  `qnx800-guest-2.ifs`.
- Shared memory address used by the example: `0x1c050000`.
- The example verifies producer/consumer activity by reading guest logs under
  `/dev/shmem/`.

Verify the active shmem example on a booted target:

```sh
su root
/qnx/config/qvmtest/start-qvm-minimal-verify.sh
pidin ar | grep qvm
grep telemetry /dev/shmem/guest1-min.log
grep telemetry /dev/shmem/guest2-min.log
```

## Known Constraints

- The repository must remain public-safe and must not include QNX proprietary
  files or generated images.
- The current partition layout is fixed.
- Guest images are copied into data partitions; they are not embedded into the
  host IFS.
