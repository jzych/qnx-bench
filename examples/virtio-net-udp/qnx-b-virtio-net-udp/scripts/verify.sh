#!/bin/sh
set -u

grep udp-telemetry-server /dev/shmem/virtio-net-udp-guest2.log 2>/dev/null || true
