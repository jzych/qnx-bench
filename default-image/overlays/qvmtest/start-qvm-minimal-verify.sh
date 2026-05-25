#!/bin/sh

TESTDIR=/qnx/config/qvmtest

slay qvm >/dev/null 2>&1 || true
sleep 1

qvm @"$TESTDIR/guest2-noblk.qvmconf" >/dev/shmem/guest2-min.log 2>&1 &
sleep 2
qvm @"$TESTDIR/guest1-noblk.qvmconf" >/dev/shmem/guest1-min.log 2>&1 &
sleep 15

echo "--- guest2-log ---"
tail -100 /dev/shmem/guest2-min.log 2>/dev/null || true
echo "--- guest1-log ---"
tail -100 /dev/shmem/guest1-min.log 2>/dev/null || true
echo "--- processes ---"
pidin ar | grep -E "qvm|vdev" || true
echo "--- qvm-devices ---"
ls -l /dev/qvm /dev/qvm/* /dev/qvm/*/* /dev/vdevpeers/* 2>/dev/null || true
echo "--- slog-qvm-shmem ---"
slog2info 2>/dev/null | grep -i -E "qvm|vdev|shmem|hypervisor" | tail -160 || true
