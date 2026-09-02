#!/bin/sh

# Dynamically apply RAM tuning if installed
if [ -x /usr/bin/zram-tune ]; then
    /usr/bin/zram-tune
fi
if [ -x /usr/bin/zswap-tune ]; then
    /usr/bin/zswap-tune
fi

echo "=== Preparing VFIO Passthrough ==="
for dev in "0000:01:00.0" "0000:00:05.0" "0000:00:07.0" "0000:00:08.0"; do
    if [ -e "/sys/bus/pci/devices/$dev" ]; then
        echo "Binding $dev to vfio-pci..."
        echo "$dev" > /sys/bus/pci/devices/$dev/driver/unbind 2>/dev/null || true
        echo "vfio-pci" > /sys/bus/pci/devices/$dev/driver_override
        echo "$dev" > /sys/bus/pci/drivers_probe
    else
        echo "Warning: Device $dev not found on PCI bus!"
    fi
done

echo "=== Preparing Guest Kernel (FD Trick) ==="
exec 3< /guest-Image
rm -f /guest-Image

echo "=== Enabling KSM (Kernel Samepage Merging) ==="
if [ -d /sys/kernel/mm/ksm ]; then
    echo 100 > /sys/kernel/mm/ksm/pages_to_scan
    echo 200 > /sys/kernel/mm/ksm/sleep_millisecs
    echo 1 > /sys/kernel/mm/ksm/run
fi

echo "=== Launching Nested Guest (QEMU) ==="
exec qemu-system-aarch64 \
    -machine virt,gic-version=3 \
    -cpu host \
    -enable-kvm \
    -m 300 \
    -daemonize \
    -smp 1 \
    -name yocto_gui_guest \
    -kernel /proc/self/fd/3 \
    -drive file=/dev/vdb,format=raw,if=virtio \
    -device virtio-iommu-pci,boot-bypass=off \
    -device virtio-balloon-pci,free-page-reporting=on,deflate-on-oom=on \
    -device vfio-pci,host=0000:01:00.0 \
    -device vfio-pci,host=0000:00:05.0 \
    -device vfio-pci,host=0000:00:07.0 \
    -device vfio-pci,host=0000:00:08.0 \
    -append "root=/dev/vda rw console=tty0 console=hvc0 swiotlb=force init_on_free=1 iommu.strict=1 iommu.passthrough=0"
