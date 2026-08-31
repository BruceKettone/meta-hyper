require qemu-host-image.inc
SUMMARY = "Hypervisor Host Image with QEMU (ZSWAP Enabled)"

IMAGE_INSTALL += "util-linux-mkswap util-linux-swaponoff"
