#!/bin/sh
grep telemetry /dev/shmem/guest2-min.log 2>/dev/null || true
