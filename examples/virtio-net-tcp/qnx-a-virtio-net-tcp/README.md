# Guest A Virtio-Net TCP Telemetry Client

Guest A configures a virtio-net interface as `192.168.10.1/24` and runs
`net-telemetry-client`. The client connects to Guest B at `192.168.10.2:5001`
and sends newline-delimited telemetry records once per second by default.

Build from the repository root:

```powershell
.\examples\virtio-net-tcp\qnx-a-virtio-net-tcp\scripts\build.ps1
```

The generated example IFS is:

```text
.work\bsp\hyp-guest-arm\images\guest-1\qnx800-guest-1-virtio-net-tcp.ifs
```
