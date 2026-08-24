SUMMARY = "Custom Minimal Linux Kernel for Host Micro-Hypervisor"
SECTION = "kernel"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

KBRANCH = "linux-6.19.y"
LINUX_KERNEL_TYPE = "tiny"
KCONFIG_MODE = "--allnoconfig"

inherit kernel
require recipes-kernel/linux/linux-yocto.inc

LINUX_VERSION ?= "6.19.14"
LINUX_VERSION_EXTENSION:append = "-tiny-host"

# Yocto fragments removed (switched to mainline kernel.org)

KCONF_BSP_AUDIT_LEVEL = "2"

SRCREV_machine = "v6.19.14"

PV = "${LINUX_VERSION}+git"

SRC_URI = "git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git;branch=${KBRANCH};name=machine;protocol=https \
           file://defconfig \
           file://minimal-boot.cfg \
           file://shell-enablement.cfg \
           file://debug.cfg \
           file://lkvm-enablement.cfg \
           file://shrink-smmuv3-queues-6.19.patch"

# Dynamically pull in the swap feature defined by the multiconfig
SRC_URI += "${@ 'file://' + d.getVar('HOST_SWAP_FEATURE') if d.getVar('HOST_SWAP_FEATURE') else '' }"
KERNEL_FEATURES += "${@ d.getVar('HOST_SWAP_FEATURE') if d.getVar('HOST_SWAP_FEATURE') else '' }"

PROVIDES += "virtual/kernel linux-host-tiny"
COMPATIBLE_MACHINE = ".*"
