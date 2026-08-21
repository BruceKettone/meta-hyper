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
                 ca-certificates"

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

ROOTFS_POSTPROCESS_COMMAND += "remove_crashing_libinput; "
