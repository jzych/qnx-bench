#!/bin/sh
set -u

grep udp-telemetry-client /dev/shmem/virtio-net-udp-guest1.log 2>/dev/null || true
