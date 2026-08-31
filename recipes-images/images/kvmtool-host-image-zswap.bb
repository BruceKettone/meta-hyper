require kvmtool-host-image.inc
SUMMARY = "Hypervisor Host Image (ZSWAP Enabled)"

# Zswap is controlled via sysfs, so standard coreutils/busybox 'echo' is sufficient.
# We include swap utilities just in case a traditional backing swapfile is used for control tests.
IMAGE_INSTALL += "util-linux-mkswap util-linux-swaponoff zswap-tune"
