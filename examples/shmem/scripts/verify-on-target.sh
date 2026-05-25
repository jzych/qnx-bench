#!/bin/sh
set -u

echo "--- qvm processes ---"
pidin ar | grep qvm || true

echo "--- qvm devices ---"
ls -la /dev/qvm /dev/qvm/* /dev/vdevpeers 2>/dev/null || true

echo "--- telemetry ---"
grep telemetry /dev/shmem/guest1-min.log 2>/dev/null || true
grep telemetry /dev/shmem/guest2-min.log 2>/dev/null || true
