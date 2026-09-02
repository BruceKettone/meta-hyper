SUMMARY = "Custom Minimal Linux Kernel for Host Micro-Hypervisor"
SECTION = "kernel"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

KBRANCH = "master"
LINUX_KERNEL_TYPE = "tiny"
KCONFIG_MODE = "--allnoconfig"

inherit kernel
require recipes-kernel/linux/linux-yocto.inc

LINUX_VERSION ?= "7.2.0-rc5"
LINUX_VERSION_EXTENSION:append = "-tiny-host"

KCONF_BSP_AUDIT_LEVEL = "0"
do_kernel_configcheck[noexec] = "1"

SRCREV_machine = "v7.2-rc5"

PV = "${LINUX_VERSION}+git"

SRC_URI = "git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git;branch=${KBRANCH};name=machine;protocol=https \
           file://defconfig \
           file://minimal-boot.cfg \
           file://shell-enablement.cfg \
           file://debug.cfg \
           file://lkvm-enablement.cfg \
           file://vfio-enablement.cfg \
           file://shrink-smmuv3-queues-7.2.patch"

# Dynamically pull in the swap feature defined by the multiconfig
SRC_URI += "${@ 'file://' + d.getVar('HOST_SWAP_FEATURE') if d.getVar('HOST_SWAP_FEATURE') else '' }"

# Dynamically append guest config if built for the guest-zswap multiconfig
SRC_URI += "${@'file://guest.cfg file://guest-kvm.cfg' if d.getVar('BB_CURRENT_MC') == 'guest-zswap' else ''}"

# Dynamically append yocto-kernel-cache metadata when built for guest-zswap multiconfig
KMETA = "${@'kernel-meta' if d.getVar('BB_CURRENT_MC') == 'guest-zswap' else ''}"
SRCREV_meta = "${@'7b09e5efab49e4bae0c69f7f2c65b4df00e9c565' if d.getVar('BB_CURRENT_MC') == 'guest-zswap' else ''}"
SRC_URI += "${@'git://git.yoctoproject.org/yocto-kernel-cache;type=kmeta;name=meta;branch=yocto-6.18;destsuffix=kernel-meta;protocol=https' if d.getVar('BB_CURRENT_MC') == 'guest-zswap' else ''}"

PROVIDES += "virtual/kernel linux-host-tiny"
COMPATIBLE_MACHINE = ".*"
