require guest-image.inc
SUMMARY = "Guest Image - ZRAM"
IMAGE_INSTALL:append = " util-linux-zramctl zram-tune"

auto_configure_zram() {
    mkdir -p "${IMAGE_ROOTFS}/etc/init.d"
    mkdir -p "${IMAGE_ROOTFS}/etc/rc5.d"
    
    cat << 'EOF' > "${IMAGE_ROOTFS}/etc/init.d/zram-tune-init"
#!/bin/sh
echo "Starting memory tuning (ZRAM)..."
if [ -x /usr/bin/zram-tune ]; then
    /usr/bin/zram-tune
fi
EOF
    chmod +x "${IMAGE_ROOTFS}/etc/init.d/zram-tune-init"
    ln -sf ../init.d/zram-tune-init "${IMAGE_ROOTFS}/etc/rc5.d/S05zram-tune-init"
}

ROOTFS_POSTPROCESS_COMMAND += "auto_configure_zram; "
