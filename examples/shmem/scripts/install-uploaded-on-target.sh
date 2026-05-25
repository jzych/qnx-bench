#!/bin/sh
set -u

UPLOAD_DIR=/qnx/config/upload
GUEST1_DIR=/qnx/system_a/guests/qnx-guest-1
GUEST2_DIR=/qnx/system_b/guests/qnx-guest-2

if [ "$(id -u)" != "0" ]; then
    echo "Run as root: su root"
    exit 1
fi

if [ -x /scripts/mount_gpt_layout.sh ]; then
    /scripts/mount_gpt_layout.sh >/dev/null 2>&1 || true
fi

mkdir -p "$GUEST1_DIR" "$GUEST2_DIR"

if [ ! -f "$UPLOAD_DIR/qnx800-guest-1.ifs" ]; then
    echo "Missing $UPLOAD_DIR/qnx800-guest-1.ifs"
    exit 1
fi

if [ ! -f "$UPLOAD_DIR/qnx800-guest-2.ifs" ]; then
    echo "Missing $UPLOAD_DIR/qnx800-guest-2.ifs"
    exit 1
fi

cp "$UPLOAD_DIR/qnx800-guest-1.ifs" "$GUEST1_DIR/qnx800-guest-1.ifs"
cp "$UPLOAD_DIR/qnx800-guest-2.ifs" "$GUEST2_DIR/qnx800-guest-2.ifs"
chmod 0644 "$GUEST1_DIR/qnx800-guest-1.ifs" "$GUEST2_DIR/qnx800-guest-2.ifs"

sync

echo "--- installed guest images ---"
ls -l "$GUEST1_DIR/qnx800-guest-1.ifs" "$GUEST2_DIR/qnx800-guest-2.ifs"
