#!/bin/sh
set -u

CONFIG_DIR=/qnx/config/virtio-net-udp

if [ "$(id -u)" != "0" ]; then
    exec su root -c "$CONFIG_DIR/run-on-target.sh"
fi

if [ -x /scripts/mount_gpt_layout.sh ]; then
    /scripts/mount_gpt_layout.sh >/dev/null 2>&1 || true
fi

slay qvm >/dev/null 2>&1 || true
sleep 1
if pidin ar | grep -q " qvm @"; then
    slay -f qvm >/dev/null 2>&1 || true
    sleep 1
fi

qvm @"$CONFIG_DIR/qnx800-guest-2-virtio-net-udp.qvmconf" >/dev/shmem/virtio-net-udp-guest2.log 2>&1 &
sleep 3
qvm @"$CONFIG_DIR/qnx800-guest-1-virtio-net-udp.qvmconf" >/dev/shmem/virtio-net-udp-guest1.log 2>&1 &
sleep 15

echo "--- guest2-log ---"
tail -100 /dev/shmem/virtio-net-udp-guest2.log 2>/dev/null || true
echo "--- guest1-log ---"
tail -100 /dev/shmem/virtio-net-udp-guest1.log 2>/dev/null || true
echo "--- qvm processes ---"
pidin ar | grep -E "qvm|vdev" || true
echo "--- qvm devices ---"
ls -l /dev/qvm /dev/qvm/* /dev/qvm/*/* 2>/dev/null || true
