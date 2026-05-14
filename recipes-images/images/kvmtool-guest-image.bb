SUMMARY = "Nested Guest Image"

IMAGE_INSTALL = "kernel-image"

IMAGE_LINGUAS = "en-us"

LICENSE = "MIT"

inherit core-image

IMAGE_ROOTFS_SIZE ?= "8192"
IMAGE_ROOTFS_EXTRA_SPACE:append = "${@bb.utils.contains("DISTRO_FEATURES", "systemd", " + 4096", "", d)}"

