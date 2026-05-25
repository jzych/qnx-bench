# Troubleshooting

## SSH Host Key Changed

When reflashing the SD card, SSH can reject the host key:

```powershell
ssh-keygen -R 192.168.0.31
ssh qnxuser@192.168.0.31
```

Use the current target IP if it changed.

## qconn Not Found

Verify the host IFS was built with the remote-debug overlay:

```sh
which qconn
pidin ar | grep qconn
```

If missing, rebuild the default image and confirm the host build overlay was
applied before `make`.

## Screen Is Running But Display Is Black

Check Screen and DRM state:

```sh
pidin ar | grep screen
cat /tmp/drm-detect-displays.log
slog2info | grep -i screen
```

The expected working HDMI output has been HDMI-A-1 / HDMI0.

## Guests Do Not Start After Reboot

This is expected for the default image. Guest autostart is disabled. Start them
manually:

```sh
su root
/qnx/config/qvmtest/start-qvm-minimal-verify.sh
```

## Missing qvmtest Directory

If `/qnx/config/qvmtest/start-qvm-minimal-verify.sh` is missing, rebuild the GPT
image with `default-image/scripts/build-gpt-image.ps1`. The script stages qvmtest
helpers into the config partition.
