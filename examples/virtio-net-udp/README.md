# Virtio-Net UDP Guest-to-Guest Example

This example runs two QNX guests connected by a direct guest-to-guest
`virtio-net` link. Guest B listens for UDP telemetry on `192.168.10.2:5002`.
Guest A configures `192.168.10.1/24` and sends newline-delimited telemetry
datagrams. Guest B sends ACK datagrams back by default.

## Build

From the repository root:

```powershell
.\examples\virtio-net-udp\scripts\build-all.ps1
```

The scripts patch the disposable guest BSP workspace under `.work\bsp\` and
produce:

- `.work\bsp\hyp-guest-arm\images\guest-1\qnx800-guest-1-virtio-net-udp.ifs`
- `.work\bsp\hyp-guest-arm\images\guest-2\qnx800-guest-2-virtio-net-udp.ifs`

## Upload And Install

Replace `[ip-address]` with the target IP.

```powershell
.\examples\virtio-net-udp\scripts\upload-all.ps1 -Target [ip-address] -User qnxuser
```

On the target:

```sh
su root
sh /qnx/config/upload/install-virtio-net-udp-guests.sh
```

## Run

On the target:

```sh
sh /qnx/config/virtio-net-udp/run-on-target.sh
sh /qnx/config/virtio-net-udp/verify-on-target.sh
```

The client and server logs include stable grep targets:

- `udp-telemetry-client:`
- `udp-telemetry-server:`
