SUMMARY = "Hypervisor Host Image (Base)"
IMAGE_INSTALL = "packagegroup-core-boot kvmtool kernel-image"
IMAGE_LINGUAS = "en-us"
LICENSE = "MIT"
inherit core-image
IMAGE_FSTYPES = "ext4"
IMAGE_ROOTFS_SIZE ?= "8192"
IMAGE_ROOTFS_EXTRA_SPACE:append = "${@bb.utils.contains("DISTRO_FEATURES", "systemd", " + 4096", "", d)}"
