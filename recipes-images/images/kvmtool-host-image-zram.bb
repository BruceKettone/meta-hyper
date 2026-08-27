require kvmtool-host-image.inc
SUMMARY = "Hypervisor Host Image (ZRAM Enabled)"

# util-linux provides zramctl, mkswap, and swapon required to format and mount the ZRAM device
IMAGE_INSTALL += "util-linux-zramctl util-linux-mkswap util-linux-swaponoff zram-tune host-logger"
