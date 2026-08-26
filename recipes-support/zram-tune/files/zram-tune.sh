#!/bin/sh
echo "=== Tuning Host Memory & ZRAM (Extreme Limits) ==="

# Stop artificial OOM inflation
if [ -f /proc/sys/vm/watermark_boost_factor ]; then
    echo 0 > /proc/sys/vm/watermark_boost_factor
fi

if [ -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
    echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi

# Force the host to drop all leftover boot caches
echo 3 > /proc/sys/vm/drop_caches
echo 500 > /proc/sys/vm/vfs_cache_pressure

# Extreme Low-Memory Watermarks
echo 0 > /proc/sys/vm/page-cluster
echo 100 > /proc/sys/vm/swappiness
echo 50 > /proc/sys/vm/watermark_scale_factor
echo 1 > /proc/sys/vm/overcommit_memory
echo 4096 > /proc/sys/vm/min_free_kbytes

# Supercharge KSM Deduplication
echo 1000 > /sys/kernel/mm/ksm/pages_to_scan
echo 10 > /sys/kernel/mm/ksm/sleep_millisecs
echo 1 > /sys/kernel/mm/ksm/run

# Modern LRU
echo y > /sys/kernel/mm/lru_gen/enabled
echo 1000 > /sys/kernel/mm/lru_gen/min_ttl_ms 2>/dev/null || true

if ! grep -q "/dev/zram0" /proc/swaps; then
    echo 350M > /sys/block/zram0/disksize
    mkswap /dev/zram0
    swapon -p 100 /dev/zram0
else
    echo "ZRAM is already active, skipping setup."
fi


