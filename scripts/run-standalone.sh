#!/bin/bash

# Exit immediately if a simple command fails
set -e

# --- Command Line Arguments ---
if [ -z "$1" ]; then
    echo "Usage: $0 [reference|zram|zswap] [STANDALONE_RAM_MB]"
    echo "Example: $0 zswap 300"
    exit 1
fi
MC_VARIANT="$1"
STANDALONE_RAM="${2:-300}"

# --- Dynamic Path Resolution ---
if [ -n "$BUILDDIR" ]; then
    # Use Yocto's native environment variable if the user sourced init-build-env
    BUILD_ROOT="$BUILDDIR"
else
    # Fallback to relative path traversal if run in a fresh terminal
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    BUILD_ROOT="${PROJECT_ROOT}/build"
fi

if [ "$MC_VARIANT" = "reference" ]; then
    MC_SUFFIX="guest"
else
    MC_SUFFIX="guest-${MC_VARIANT}"
fi

BUILD_DIR_STANDALONE="${BUILD_ROOT}/tmp-${MC_SUFFIX}/deploy/images/lkvm-arm64"

# --- Target Files ---
KERNEL_IMG="${BUILD_DIR_STANDALONE}/Image"
ROOTFS_IMG="${BUILD_DIR_STANDALONE}/guest-image-${MC_VARIANT}-lkvm-arm64.rootfs.ext4"

# --- Pre-Flight Checks ---
echo "Verifying boot files for Standalone Guest (${MC_VARIANT})..."
for FILE in "$KERNEL_IMG" "$ROOTFS_IMG"; do
    if [ ! -f "$FILE" ]; then
        echo "Error: Missing required file: $FILE"
        echo "Make sure you have run the Yocto build for mc:${MC_SUFFIX}:guest-image-${MC_VARIANT}."
        exit 1
    fi
done

echo "Booting Standalone Guest (${MC_VARIANT} variant)..."

CMDLINE="root=/dev/vda rw rootfstype=ext4 console=ttyAMA0 sysctl.vm.min_free_kbytes=2048 sysctl.vm.watermark_boost_factor=0 sysctl.vm.watermark_scale_factor=100 sysctl.vm.extfrag_threshold=1000 sysctl.vm.swappiness=150 sysctl.vm.vfs_cache_pressure=150"

if [ "$MC_VARIANT" = "zswap" ]; then
    CMDLINE="${CMDLINE} zswap.enabled=1 zswap.max_pool_percent=60"
elif [ "$MC_VARIANT" = "zram" ]; then
    CMDLINE="${CMDLINE} zswap.enabled=0"
fi

qemu-system-aarch64 \
  -machine virt,virtualization=on,gic-version=3 \
  -cpu cortex-a57 \
  -monitor tcp:0.0.0.0:4444,server,nowait \
  -m "${STANDALONE_RAM}M" \
  -snapshot \
  -kernel "${KERNEL_IMG}" \
  -drive if=none,file="${ROOTFS_IMG}",format=raw,id=hd0 \
  -device virtio-blk-pci,drive=hd0,disable-legacy=on,addr=0x03 \
  -netdev user,id=net0 \
  -audiodev spice,id=snd0 -device intel-hda,addr=0x05 -device hda-output,audiodev=snd0 \
  -device pcie-root-port,id=pcie.1,chassis=1,slot=1,addr=0x06 \
  -device e1000e,netdev=net0,bus=pcie.1 \
  -device bochs-display,id=gpu0,romfile="",addr=0x07 \
  -device usb-ehci,id=usbbus,addr=0x08 \
  -device usb-kbd,bus=usbbus.0 \
  -device usb-tablet,bus=usbbus.0 \
  -spice port=5900,disable-ticketing=on \
  -serial stdio \
  -append "${CMDLINE}"
