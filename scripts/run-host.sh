#!/bin/bash

# Exit immediately if a simple command fails
set -e

# --- Command Line Arguments ---
if [ -z "$1" ]; then
    echo "Usage: $0 [reference|zram|zswap]"
    echo "Example: $0 zswap"
    exit 1
fi
MC_VARIANT="$1"
HOST_RAM="${2:-1024}"

# --- Dynamic Path Resolution ---
if [ -n "$BUILDDIR" ]; then
    # Use Yocto's native environment variable if the user sourced oe-init-build-env
    BUILD_ROOT="$BUILDDIR"
else
    # Fallback to relative path traversal if run in a fresh terminal
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
    BUILD_ROOT="${PROJECT_ROOT}/build"
fi

BUILD_DIR_HOST="${BUILD_ROOT}/tmp-host-${MC_VARIANT}/deploy/images/hyper-host-arm64"

# --- Target Files ---
KERNEL_IMG="${BUILD_DIR_HOST}/Image"
ROOTFS_IMG="${BUILD_DIR_HOST}/kvmtool-host-image-${MC_VARIANT}-hyper-host-arm64.rootfs.ext4"
BUILD_DIR_GUEST="${BUILD_ROOT}/tmp-guest/deploy/images/lkvm-arm64"
GUEST_FS_IMG="${BUILD_DIR_GUEST}/kvmtool-guest-image-lkvm-arm64.rootfs.ext4"

# --- Pre-Flight Checks ---
echo "Verifying boot files..."
for FILE in "$KERNEL_IMG" "$ROOTFS_IMG" "$GUEST_FS_IMG"; do
    if [ ! -f "$FILE" ]; then
        echo "Error: Missing required file: $FILE"
        echo "Make sure you have run the Yocto build and the build-guest.sh script."
        exit 1
    fi
done

echo "Booting the QEMU Host..."

# --- Launch QEMU ---
qemu-system-aarch64 \
  -machine virt,virtualization=on,iommu=smmuv3,gic-version=3 \
  -cpu cortex-a57 \
  -m "${HOST_RAM}M" \
  -snapshot \
  -kernel "${KERNEL_IMG}" \
  -device pcie-root-port,id=pcie.1,chassis=1,slot=1 \
  -drive if=none,file="${ROOTFS_IMG}",format=raw,id=hd0 \
  -device virtio-blk-pci,drive=hd0,disable-legacy=on \
  -drive if=none,file="${GUEST_FS_IMG}",format=raw,id=hd1 \
  -device virtio-blk-pci,drive=hd1,disable-legacy=on \
  -netdev user,id=net0 \
  -audiodev spice,id=snd0 -device intel-hda -device hda-output,audiodev=snd0 \
  -device pcie-root-port,id=pcie.2,chassis=2,slot=2 \
  -device e1000e,netdev=net0,bus=pcie.2 \
  -device bochs-display,id=gpu0,romfile="" \
  -device usb-ehci,id=usbbus \
  -device usb-kbd,bus=usbbus.0 \
  -device usb-tablet,bus=usbbus.0 \
  -spice port=5900,disable-ticketing=on \
  -serial stdio \
  -append "root=/dev/vda rw console=ttyAMA0 iommu.passthrough=0 iommu.strict=1 nomodeset vfio_iommu_type1.allow_unsafe_interrupts=1"
