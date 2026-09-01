#!/bin/sh
# Usage: host-logger start /tmp/run1 zswap lkvm
#        host-logger stop

COMMAND=$1
OUTFILE="${2}_${3}_${4}_metrics.csv"
PIDFILE="/tmp/host_logger.pid"

if [ "$COMMAND" = "start" ]; then
    if [ -f "$PIDFILE" ]; then
        echo "Logger is already running! (PID: $(cat $PIDFILE))"
        exit 1
    fi

    echo "timestamp_rel,mem_free,mem_slab,ksm_sharing,pgmajfault,engine_pool,engine_stored,engine_rejected" > $OUTFILE

    # Wait loop so you can perfectly sync with the guest
    echo "Ready. Press [ENTER] to capture T=0 and detach to background..."
    read dummy
    START_TIME=$(awk '{print $1}' /proc/uptime)

    # Launch the actual logging loop into the background
    (
        while true; do
            NOW=$(awk '{print $1}' /proc/uptime)
            T_REL=$(awk "BEGIN {printf \"%.2f\", $NOW - $START_TIME}")

            MEM_FREE=$(awk '/MemFree/ {print $2}' /proc/meminfo)
            MEM_SLAB=$(awk '/Slab/ {print $2}' /proc/meminfo)
            KSM_SHARING=$(cat /sys/kernel/mm/ksm/pages_sharing 2>/dev/null || echo 0)
            PG_MAJFAULT=$(awk '/pgmajfault/ {print $2}' /proc/vmstat 2>/dev/null || echo 0)

            if [ "$3" = "zswap" ]; then
                ENG_POOL=$(cat /sys/kernel/debug/zswap/pool_total_size 2>/dev/null || echo 0)
                ENG_STORED=$(cat /sys/kernel/debug/zswap/stored_pages 2>/dev/null || echo 0)
                ENG_REJ=$(cat /sys/kernel/debug/zswap/reject_compress_poor 2>/dev/null || echo 0)
            else
                ZSTAT=$(cat /sys/block/zram0/mm_stat 2>/dev/null || echo "0 0 0 0 0")
                ENG_STORED=$(echo $ZSTAT | awk '{print $1}')
                ENG_POOL=$(echo $ZSTAT | awk '{print $3}')
                ENG_REJ=0
            fi

            echo "$T_REL,$MEM_FREE,$MEM_SLAB,$KSM_SHARING,$PG_MAJFAULT,$ENG_POOL,$ENG_STORED,$ENG_REJ" >> $OUTFILE
            sleep 1
        done
    ) >/dev/null 2>&1 &

    # Save the PID of the background job
    echo $! > $PIDFILE
    echo "Logging detached. Terminal is yours. Run 'host-logger stop' to end."

elif [ "$COMMAND" = "stop" ]; then
    if [ -f "$PIDFILE" ]; then
        kill $(cat $PIDFILE)
        rm -f $PIDFILE
        echo "Logging safely stopped."
    else
        echo "No logger process found."
    fi
else
    echo "Usage: host-logger [start|stop] [outfile_prefix] [engine] [hypervisor]"
fi
