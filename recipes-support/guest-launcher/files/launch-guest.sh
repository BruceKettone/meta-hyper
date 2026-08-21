#!/bin/sh

echo "=== Preparing VFIO Passthrough ==="
for dev in "0000:00:01.0" "0000:00:03.0" "0000:00:04.0" "0000:00:05.0" "0000:00:06.0"; do
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

echo "=== Launching Nested Guest (lkvm) ==="
exec lkvm run --debug \
    -k /proc/self/fd/3 \
    -m 210 \
    -c 1 \
    --name yocto_gui_guest \
    --vfio-pci 0000:00:01.0 \
    --vfio-pci 0000:00:03.0 \
    --vfio-pci 0000:00:04.0 \
    --vfio-pci 0000:00:05.0 \
    --vfio-pci 0000:00:06.0 \
    --irqchip gicv3-its \
    --console virtio \
    -p "root=/dev/vda rw console=tty0 console=hvc0"
