# Guest B Virtio-Net TCP Telemetry Server

Guest B configures a virtio-net interface as `192.168.10.2/24` and runs
`net-telemetry-server`. The server listens on `0.0.0.0:5001`, accepts one TCP
client at a time, and logs each received telemetry line.

Build from the repository root:

```powershell
.\examples\virtio-net-tcp\qnx-b-virtio-net-tcp\scripts\build.ps1
```

The generated example IFS is:

```text
.work\bsp\hyp-guest-arm\images\guest-2\qnx800-guest-2-virtio-net-tcp.ifs
```
