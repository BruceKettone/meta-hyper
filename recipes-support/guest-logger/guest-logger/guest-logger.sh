#!/bin/sh
# Usage: guest-logger start /tmp/run1
#        guest-logger stop

COMMAND=$1
OUTFILE="${2}_guest_metrics.csv"
PIDFILE="/tmp/guest_logger.pid"

if [ "$COMMAND" = "start" ]; then
    if [ -f "$PIDFILE" ]; then
        echo "Logger is already running! (PID: $(cat $PIDFILE))"
        exit 1
    fi

    echo echo "timestamp_rel,mem_total,mem_available,anon_pages,pgmajfault,psi_mem_full,oom_kills" > $OUTFILE
    OOM_BASE=$(awk '/oom_kill/ {print $2}' /proc/vmstat 2>/dev/null || echo 0)

    # Wait loop so you can perfectly sync with the host
    echo "Ready. Press [ENTER] to capture T=0 and detach to background..."
    read dummy
    START_TIME=$(awk '{print $1}' /proc/uptime)

    # Launch the actual logging loop into the background
    (
        while true; do
            NOW=$(awk '{print $1}' /proc/uptime)
            T_REL=$(awk "BEGIN {printf \"%.2f\", $NOW - $START_TIME}")

            MEM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
            MEM_AVAIL=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
            ANON_PAGES=$(awk '/AnonPages/ {print $2}' /proc/meminfo)
            OOM_CURRENT=$(dmesg | grep -c "Out of memory")
            OOM_DELTA=$((OOM_CURRENT - OOM_BASE))

            echo "$T_REL,$MEM_TOTAL,$MEM_AVAIL,$ANON_PAGES,$OOM_DELTA" >> $OUTFILE
            sleep 1
        done
    ) >/dev/null 2>&1 &

    # Save the Process ID (PID) of the background job
    echo $! > $PIDFILE
    echo "Logging detached. Terminal is yours. Run 'guest-logger stop' to end."

elif [ "$COMMAND" = "stop" ]; then
    if [ -f "$PIDFILE" ]; then
        kill $(cat $PIDFILE)
        rm -f $PIDFILE
        echo "Logging safely stopped."
        echo "Upload with: cat /tmp/*_guest_metrics.csv | nc termbin.com 9999"
    else
        echo "No logger process found."
    fi
else
    echo "Usage: guest-logger [start|stop] [outfile_prefix]"
fi
