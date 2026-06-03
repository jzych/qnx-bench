# Guest A Virtio-Net UDP Telemetry Client

Guest A configures a virtio-net interface as `192.168.10.1/24` and runs
`udp-telemetry-client`. The client sends newline-delimited telemetry datagrams
to Guest B at `192.168.10.2:5002` once per second by default and logs ACKs when
ACK support is enabled.

Build from the repository root:

```powershell
.\examples\virtio-net-udp\qnx-a-virtio-net-udp\scripts\build.ps1
```

The generated example IFS is:

```text
.work\bsp\hyp-guest-arm\images\guest-1\qnx800-guest-1-virtio-net-udp.ifs
```
