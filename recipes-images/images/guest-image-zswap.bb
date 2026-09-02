require guest-image.inc
SUMMARY = "Guest Image - ZSWAP"
IMAGE_INSTALL:append = " zswap-tune"

auto_configure_zswap() {
    mkdir -p "${IMAGE_ROOTFS}/etc/init.d"
    mkdir -p "${IMAGE_ROOTFS}/etc/rc5.d"
    
    cat << 'EOF' > "${IMAGE_ROOTFS}/etc/init.d/zswap-tune-init"
#!/bin/sh
echo "Starting memory tuning (ZSWAP)..."
if [ -x /usr/bin/zswap-tune ]; then
    /usr/bin/zswap-tune
fi
EOF
    chmod +x "${IMAGE_ROOTFS}/etc/init.d/zswap-tune-init"
    ln -sf ../init.d/zswap-tune-init "${IMAGE_ROOTFS}/etc/rc5.d/S05zswap-tune-init"
}

ROOTFS_POSTPROCESS_COMMAND += "auto_configure_zswap; "
