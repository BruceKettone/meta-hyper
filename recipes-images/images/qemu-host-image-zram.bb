require qemu-host-image.inc
SUMMARY = "Hypervisor Host Image with QEMU (ZRAM Enabled)"

IMAGE_INSTALL += "util-linux-zramctl util-linux-mkswap util-linux-swaponoff zram-tune host-logger"
