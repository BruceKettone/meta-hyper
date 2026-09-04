#!/bin/sh
echo "=== Tuning Host Memory & Virtual ZSWAP (Standalone) ==="

if [ -f /proc/sys/vm/watermark_boost_factor ]; then
    echo 0 > /proc/sys/vm/watermark_boost_factor
fi
if [ -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
    echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi

echo 3 > /proc/sys/vm/drop_caches
echo 500 > /proc/sys/vm/vfs_cache_pressure
echo 0 > /proc/sys/vm/page-cluster
echo 150 > /proc/sys/vm/swappiness
echo 100 > /proc/sys/vm/watermark_scale_factor
echo 1 > /proc/sys/vm/overcommit_memory
echo 2048 > /proc/sys/vm/min_free_kbytes

echo 1000 > /sys/kernel/mm/ksm/pages_to_scan
echo 10 > /sys/kernel/mm/ksm/sleep_millisecs
echo 1 > /sys/kernel/mm/ksm/run
if pgrep -x ksmd >/dev/null; then
    renice -n -20 -p $(pgrep -x ksmd) 2>/dev/null || true
fi

if [ -d /sys/kernel/mm/lru_gen ]; then
    echo y > /sys/kernel/mm/lru_gen/enabled 2>/dev/null || true
    echo 1000 > /sys/kernel/mm/lru_gen/min_ttl_ms 2>/dev/null || true
fi

# ==========================================
# 4. Standalone ZSWAP Tuning
# ==========================================


echo 60 > /sys/module/zswap/parameters/max_pool_percent
echo Y > /sys/module/zswap/parameters/enabled

echo "Standalone ZSWAP enabled successfully."
