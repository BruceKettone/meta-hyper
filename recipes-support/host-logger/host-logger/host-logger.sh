#!/bin/sh

echo "Time,Host_Used_MB,Host_Free_MB,Swap_Used_MB,ZRAM_Payload_MB,ZRAM_Physical_MB,Comp_Ratio" > host_metrics.csv
echo "Starting Host Telemetry... Logging to host_metrics.csv. Press Ctrl+C to stop."

while true; do
    awk -v ts="$(date +%T)" '
    BEGIN { h_tot=0; h_free=0; s_tot=0; s_free=0; z_orig=0; z_phys=0; }

    FILENAME == "/proc/meminfo" {
        if ($1 == "MemTotal:") h_tot = $2 / 1024;
        if ($1 == "MemFree:") h_free = $2 / 1024;
        if ($1 == "SwapTotal:") s_tot = $2 / 1024;
        if ($1 == "SwapFree:") s_free = $2 / 1024;
    }

    FILENAME == "/sys/block/zram0/mm_stat" {
        z_orig = $1 / 1048576;
        z_phys = $3 / 1048576;
    }

    END {
        ratio = (z_phys > 0) ? (z_orig / z_phys) : 0;
        printf "%s,%.1f,%.1f,%.1f,%.1f,%.1f,%.2f\n", ts, h_tot-h_free, h_free, s_tot-s_free, z_orig, z_phys, ratio;
    }' /proc/meminfo /sys/block/zram0/mm_stat >> host_metrics.csv

    sleep 1
done
