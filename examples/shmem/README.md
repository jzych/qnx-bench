# Shared Memory Example

Two QNX generic ARM Hypervisor guests exchange telemetry through a host
configured shared-memory vdev.

- `qnx-a-shmem` builds Guest A, the telemetry producer.
- `qnx-b-shmem` builds Guest B, the telemetry consumer.

The guests are copied to the target data partitions and started manually. They
are not embedded into the Raspberry Pi 5 host IFS.

See [docs/runbook.md](docs/runbook.md) for the full build, upload, run, and
verification flow.

## Target Install Paths

Guest images must be installed into the persistent QNX6 system partitions:

- Guest A producer:
  `/qnx/system_a/guests/qnx-guest-1/qnx800-guest-1.ifs`
- Guest B consumer:
  `/qnx/system_b/guests/qnx-guest-2/qnx800-guest-2.ifs`

The upload scripts first stage files in `/qnx/config/upload/`. After upload, run
the target-side install helper as root:

```sh
su root
sh /qnx/config/upload/install-shmem-guests.sh
```

That helper mounts the GPT layout if needed, creates both guest directories,
copies the uploaded IFS files to the right partitions, and runs `sync`.
