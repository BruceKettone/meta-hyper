#!/bin/sh

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

echo "=== Spawning Sysfs & TempFS Reclamation Daemon ==="
# ( sleep 5; umount -l /sys 2>/dev/null; umount -l /run 2>/dev/null; umount -l /var/volatile 2>/dev/null; echo 2 > /proc/sys/vm/drop_caches ) &

echo "=== Launching Nested Guest (lkvm) ==="
exec lkvm run --debug \
    -k /proc/self/fd/3 \
    -d /dev/vdb \
    -n mode=none \
    -m 300 \
    -c 1 \
    --name yocto_gui_guest \
    --vfio-pci 0000:01:00.0 \
    --vfio-pci 0000:00:05.0 \
    --vfio-pci 0000:00:07.0 \
    --vfio-pci 0000:00:08.0 \
    --vfio-bounce-buffer 4 \
    --irqchip gicv3-its \
    --console virtio \
    -p "root=/dev/vda rw console=tty0 console=hvc0 swiotlb=force init_on_free=1" \
    > /dev/null 2>&1 < /dev/null &

