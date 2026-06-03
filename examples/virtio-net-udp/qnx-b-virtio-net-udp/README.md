# Guest B Virtio-Net UDP Telemetry Server

Guest B configures a virtio-net interface as `192.168.10.2/24` and runs
`udp-telemetry-server`. The server binds `0.0.0.0:5002`, logs each received
telemetry datagram, and replies with ACK datagrams when ACK support is enabled.

Build from the repository root:

```powershell
.\examples\virtio-net-udp\qnx-b-virtio-net-udp\scripts\build.ps1
```

The generated example IFS is:

```text
.work\bsp\hyp-guest-arm\images\guest-2\qnx800-guest-2-virtio-net-udp.ifs
```
