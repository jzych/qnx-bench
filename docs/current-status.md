# Current Project Status

## Host

- Raspberry Pi 5 boots QNX 8.0.
- SSH access works on the bench network.
- Screen starts on HDMI0 when a display is connected.
- qconn, pdebug, and devc-pty are included for remote development/debugging.
- Hypervisor host support is included in the current booting image.
- Guest autostart is intentionally disabled.

## Hypervisor Guests

The active example is `examples/shmem`.

- Guest A: QNX 8.0 generic ARM Hypervisor guest, telemetry producer.
- Guest B: QNX 8.0 generic ARM Hypervisor guest, telemetry consumer.
- Both guests are launched manually with qvm.
- Shared memory address used by the example: `0x1c050000`.
- The example verifies producer/consumer activity by reading guest logs under
  `/dev/shmem/`.

## Known Constraints

- The repository must remain public-safe and must not include QNX proprietary
  files or generated images.
- The current partition layout is fixed.
- Guest images are copied into data partitions; they are not embedded into the
  host IFS.
