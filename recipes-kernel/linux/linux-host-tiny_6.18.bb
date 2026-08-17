SUMMARY = "Custom Minimal Linux Kernel for Host Micro-Hypervisor"
SECTION = "kernel"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

KBRANCH = "v6.18/standard/tiny/base"
LINUX_KERNEL_TYPE = "tiny"
KCONFIG_MODE = "--allnoconfig"

inherit kernel
require recipes-kernel/linux/linux-yocto.inc

LINUX_VERSION ?= "6.18.19"
LINUX_VERSION_EXTENSION:append = "-tiny-host"

# Enable built-in Yocto fragments for EXT4 and Devtmpfs
KERNEL_FEATURES = "cfg/fs/ext4.scc cfg/fs/devtmpfs.scc"

KMETA = "kernel-meta"
KCONF_BSP_AUDIT_LEVEL = "2"

SRCREV_machine = "1fa8fa91abea837d76ab91c972e8387aae78157e"
SRCREV_meta = "465cb5bcefd72f429e0b3ad6ab5b3fcff5b390fc"

PV = "${LINUX_VERSION}+git"

SRC_URI = "git://git.yoctoproject.org/linux-yocto.git;branch=${KBRANCH};name=machine;protocol=https \
           git://git.yoctoproject.org/yocto-kernel-cache;type=kmeta;name=meta;branch=yocto-6.18;destsuffix=${KMETA};protocol=https \
           file://defconfig \
           file://minimal-boot.cfg \
           file://shell-enablement.cfg \
           file://debug.cfg"

PROVIDES += "virtual/kernel linux-host-tiny"
COMPATIBLE_MACHINE = ".*"
