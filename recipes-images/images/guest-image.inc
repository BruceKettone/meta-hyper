SUMMARY = "Nested Guest Image"

IMAGE_INSTALL = "packagegroup-core-boot \
                 packagegroup-core-x11-base \
                 xserver-xorg \
                 xf86-input-evdev \
                 xf86-video-modesetting \
                 mesa \
                 mesa-megadriver \
                 dbus \
                 matchbox-wm \
                 matchbox-desktop \
                 matchbox-panel-2 \
                 xterm \
                 xkeyboard-config \
                 fontconfig \
                 xkbcomp \
                 udev-extraconf \
                 eudev-hwdb \
                 xinit \
                 xauth \
                 mpv \
                 alsa-utils \
                 ca-certificates \
                 surf \
                 time-sync \
                 web-search \
                 play-video \
                 guest-logger \
                 standalone-logger"

IMAGE_LINGUAS = ""
LICENSE = "MIT"
inherit core-image

IMAGE_FSTYPES = "ext4"
IMAGE_ROOTFS_SIZE ?= "65536"
IMAGE_ROOTFS_EXTRA_SPACE:append = "${@bb.utils.contains("DISTRO_FEATURES", "systemd", " + 4096", "", d)}"

# Strip the crashing libinput driver so Xorg falls back to evdev
remove_crashing_libinput() {
    rm -f ${IMAGE_ROOTFS}/usr/lib/xorg/modules/input/libinput_drv.so
    rm -f ${IMAGE_ROOTFS}/usr/share/X11/xorg.conf.d/40-libinput.conf
    rm -f ${IMAGE_ROOTFS}/etc/X11/xorg.conf.d/40-libinput.conf
}

# Auto-configure DHCP on eth0
auto_configure_network() {
    mkdir -p "${IMAGE_ROOTFS}/etc/init.d"
    mkdir -p "${IMAGE_ROOTFS}/etc/rc5.d"

    cat << 'EOF' > "${IMAGE_ROOTFS}/etc/init.d/force-dhcp"
#!/bin/sh
echo "Automating network bring-up..."

ip link set eth0 up
udhcpc -i eth0 -b
EOF

    chmod +x "${IMAGE_ROOTFS}/etc/init.d/force-dhcp"
    ln -sf ../init.d/force-dhcp "${IMAGE_ROOTFS}/etc/rc5.d/S99force-dhcp"
}

ROOTFS_POSTPROCESS_COMMAND += "remove_crashing_libinput; auto_configure_network; "

