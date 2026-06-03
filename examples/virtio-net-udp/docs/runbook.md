# Virtio-Net UDP Runbook

## Build On Host

From the repository root:

```powershell
.\examples\virtio-net-udp\scripts\build-all.ps1
```

Expected generated files:

- `.work\bsp\hyp-guest-arm\images\guest-1\qnx800-guest-1-virtio-net-udp.ifs`
- `.work\bsp\hyp-guest-arm\images\guest-2\qnx800-guest-2-virtio-net-udp.ifs`

## Upload

Replace `[ip-address]` with the target IP.

```powershell
.\examples\virtio-net-udp\scripts\upload-all.ps1 -Target [ip-address] -User qnxuser
```

Uploaded staging files:

- `/qnx/config/upload/qnx800-guest-1-virtio-net-udp.ifs`
- `/qnx/config/upload/qnx800-guest-2-virtio-net-udp.ifs`
- `/qnx/config/upload/qnx800-guest-1-virtio-net-udp.qvmconf`
- `/qnx/config/upload/qnx800-guest-2-virtio-net-udp.qvmconf`
- `/qnx/config/upload/run-virtio-net-udp-on-target.sh`
- `/qnx/config/upload/verify-virtio-net-udp-on-target.sh`
- `/qnx/config/upload/install-virtio-net-udp-guests.sh`

## Install On Target

```sh
su root
sh /qnx/config/upload/install-virtio-net-udp-guests.sh
```

Installed guest images:

- `/qnx/system_a/guests/qnx-guest-1/qnx800-guest-1-virtio-net-udp.ifs`
- `/qnx/system_b/guests/qnx-guest-2/qnx800-guest-2-virtio-net-udp.ifs`

Installed runtime directory:

- `/qnx/config/virtio-net-udp/`

## Run On Target

Guest B starts first so the UDP server is likely bound before Guest A starts
sending datagrams.

```sh
sh /qnx/config/virtio-net-udp/run-on-target.sh
```

Logs:

- `/dev/shmem/virtio-net-udp-guest1.log`
- `/dev/shmem/virtio-net-udp-guest2.log`

## Verify

```sh
sh /qnx/config/virtio-net-udp/verify-on-target.sh
```

Expected checks:

- Two `qvm` processes exist.
- `/dev/qvm/qnx-guest-1/guest_to_guest` exists.
- `/dev/qvm/qnx-guest-2/guest_to_guest` exists.
- `grep udp-telemetry /dev/shmem/virtio-net-udp-guest*.log` shows client sends,
  server receives, and default ACK activity.
