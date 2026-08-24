#!/bin/sh

echo "=== Preparing VFIO Passthrough ==="
for dev in "0000:01:00.0" "0000:00:03.0" "0000:02:00.0" "0000:00:05.0" "0000:00:06.0"; do
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

echo "=== Launching Nested Guest (QEMU) ==="
exec qemu-system-aarch64 \
    -machine virt,gic-version=3 \
    -cpu host \
    -enable-kvm \
    -m 300 \
    -smp 1 \
    -name yocto_gui_guest \
    -nographic \
    -kernel /proc/self/fd/3 \
    -device virtio-iommu-pci,boot-bypass=off \
    -device virtio-balloon-pci,free-page-reporting=on,deflate-on-oom=on \
    -device vfio-pci,host=0000:01:00.0 \
    -device vfio-pci,host=0000:00:03.0 \
    -device vfio-pci,host=0000:02:00.0 \
    -device vfio-pci,host=0000:00:05.0 \
    -device vfio-pci,host=0000:00:06.0 \
    -append "root=/dev/sda rw console=tty0 console=hvc0 iommu.strict=1 iommu.passthrough=0"
