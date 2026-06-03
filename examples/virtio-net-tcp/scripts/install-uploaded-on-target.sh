#!/bin/sh
set -u

UPLOAD_DIR=/qnx/config/upload
CONFIG_DIR=/qnx/config/virtio-net-tcp
GUEST1_DIR=/qnx/system_a/guests/qnx-guest-1
GUEST2_DIR=/qnx/system_b/guests/qnx-guest-2
GUEST1_IFS=qnx800-guest-1-virtio-net-tcp.ifs
GUEST2_IFS=qnx800-guest-2-virtio-net-tcp.ifs
GUEST1_CONF=qnx800-guest-1-virtio-net-tcp.qvmconf
GUEST2_CONF=qnx800-guest-2-virtio-net-tcp.qvmconf

if [ "$(id -u)" != "0" ]; then
    echo "Run as root: su root"
    exit 1
fi

if [ -x /scripts/mount_gpt_layout.sh ]; then
    /scripts/mount_gpt_layout.sh >/dev/null 2>&1 || true
fi

for file in "$GUEST1_IFS" "$GUEST2_IFS" "$GUEST1_CONF" "$GUEST2_CONF" \
    run-virtio-net-tcp-on-target.sh verify-virtio-net-tcp-on-target.sh; do
    if [ ! -f "$UPLOAD_DIR/$file" ]; then
        echo "Missing $UPLOAD_DIR/$file"
        exit 1
    fi
done

mkdir -p "$GUEST1_DIR" "$GUEST2_DIR" "$CONFIG_DIR"

cp "$UPLOAD_DIR/$GUEST1_IFS" "$GUEST1_DIR/$GUEST1_IFS"
cp "$UPLOAD_DIR/$GUEST2_IFS" "$GUEST2_DIR/$GUEST2_IFS"
chmod 0644 "$GUEST1_DIR/$GUEST1_IFS" "$GUEST2_DIR/$GUEST2_IFS"

cp "$UPLOAD_DIR/$GUEST1_CONF" "$CONFIG_DIR/$GUEST1_CONF"
cp "$UPLOAD_DIR/$GUEST2_CONF" "$CONFIG_DIR/$GUEST2_CONF"
cp "$UPLOAD_DIR/run-virtio-net-tcp-on-target.sh" "$CONFIG_DIR/run-on-target.sh"
cp "$UPLOAD_DIR/verify-virtio-net-tcp-on-target.sh" "$CONFIG_DIR/verify-on-target.sh"
chmod 0644 "$CONFIG_DIR/$GUEST1_CONF" "$CONFIG_DIR/$GUEST2_CONF"
chmod 0755 "$CONFIG_DIR/run-on-target.sh" "$CONFIG_DIR/verify-on-target.sh"

sync

echo "--- installed virtio-net TCP guest images ---"
ls -l "$GUEST1_DIR/$GUEST1_IFS" "$GUEST2_DIR/$GUEST2_IFS"
echo "--- installed virtio-net TCP runtime files ---"
ls -l "$CONFIG_DIR"
