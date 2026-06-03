#!/bin/sh
set -u

grep net-telemetry-server /dev/shmem/virtio-net-tcp-guest2.log 2>/dev/null || true
