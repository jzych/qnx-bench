# Virtio-Net TCP Runbook

## Build On Host

From the repository root:

```powershell
.\examples\virtio-net-tcp\scripts\build-all.ps1
```

Expected generated files:

- `.work\bsp\hyp-guest-arm\images\guest-1\qnx800-guest-1-virtio-net-tcp.ifs`
- `.work\bsp\hyp-guest-arm\images\guest-2\qnx800-guest-2-virtio-net-tcp.ifs`

## Upload

Replace `[ip-address]` with the target IP.

```powershell
.\examples\virtio-net-tcp\scripts\upload-all.ps1 -Target [ip-address] -User qnxuser
```

Uploaded staging files:

- `/qnx/config/upload/qnx800-guest-1-virtio-net-tcp.ifs`
- `/qnx/config/upload/qnx800-guest-2-virtio-net-tcp.ifs`
- `/qnx/config/upload/qnx800-guest-1-virtio-net-tcp.qvmconf`
- `/qnx/config/upload/qnx800-guest-2-virtio-net-tcp.qvmconf`
- `/qnx/config/upload/run-virtio-net-tcp-on-target.sh`
- `/qnx/config/upload/verify-virtio-net-tcp-on-target.sh`
- `/qnx/config/upload/install-virtio-net-tcp-guests.sh`

## Install On Target

```sh
su root
sh /qnx/config/upload/install-virtio-net-tcp-guests.sh
```

Installed guest images:

- `/qnx/system_a/guests/qnx-guest-1/qnx800-guest-1-virtio-net-tcp.ifs`
- `/qnx/system_b/guests/qnx-guest-2/qnx800-guest-2-virtio-net-tcp.ifs`

Installed runtime directory:

- `/qnx/config/virtio-net-tcp/`

## Run On Target

Guest B starts first so the TCP server is likely listening before Guest A
starts connecting.

```sh
sh /qnx/config/virtio-net-tcp/run-on-target.sh
```

Logs:

- `/dev/shmem/virtio-net-tcp-guest1.log`
- `/dev/shmem/virtio-net-tcp-guest2.log`

## Verify

```sh
sh /qnx/config/virtio-net-tcp/verify-on-target.sh
```

Expected checks:

- Two `qvm` processes exist.
- `/dev/qvm/qnx-guest-1/guest_to_guest` exists.
- `/dev/qvm/qnx-guest-2/guest_to_guest` exists.
- `grep net-telemetry /dev/shmem/virtio-net-tcp-guest*.log` shows client and
  server activity.
