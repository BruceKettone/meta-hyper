require kvmtool-host-image.inc
SUMMARY = "Hypervisor Host Image (ZSWAP Enabled)"

IMAGE_INSTALL += "util-linux-mkswap util-linux-swaponoff zswap-tune host-logger"
