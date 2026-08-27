#!/bin/sh

echo "Time,Guest_Used_MB,Guest_Free_MB,Guest_Avail_MB" > guest_metrics.csv
echo "Starting Guest Telemetry... Logging to guest_metrics.csv. Press Ctrl+C to stop."

while true; do
    awk -v ts="$(date +%T)" '
    BEGIN { g_tot=0; g_free=0; g_avail=0; }
    {
        if ($1 == "MemTotal:") g_tot = $2 / 1024;
        if ($1 == "MemFree:") g_free = $2 / 1024;
        if ($1 == "MemAvailable:") g_avail = $2 / 1024;
    }
    END {
        printf "%s,%.1f,%.1f,%.1f\n", ts, g_tot-g_free, g_free, g_avail;
    }' /proc/meminfo >> guest_metrics.csv
    sleep 1
done
