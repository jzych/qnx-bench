#!/bin/sh
set -u

grep net-telemetry-client /dev/shmem/virtio-net-tcp-guest1.log 2>/dev/null || true
