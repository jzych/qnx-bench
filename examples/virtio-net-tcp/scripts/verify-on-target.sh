#!/bin/sh
set -u

echo "--- qvm processes ---"
pidin ar | grep qvm || true

echo "--- qvm devices ---"
ls -la /dev/qvm /dev/qvm/* /dev/qvm/*/* 2>/dev/null || true

echo "--- guest-to-guest virtio-net peers ---"
ls -l /dev/qvm/qnx-guest-1/guest_to_guest /dev/qvm/qnx-guest-2/guest_to_guest 2>/dev/null || true

echo "--- net telemetry logs ---"
grep net-telemetry /dev/shmem/virtio-net-tcp-guest*.log 2>/dev/null || true
