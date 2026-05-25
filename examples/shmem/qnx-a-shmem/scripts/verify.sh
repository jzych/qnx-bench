#!/bin/sh
grep telemetry /dev/shmem/guest1-min.log 2>/dev/null || true
