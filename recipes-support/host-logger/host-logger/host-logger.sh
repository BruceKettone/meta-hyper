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

    # New Header matching 'free' command
    echo "timestamp_rel,host_total,host_used,host_free,host_buff_cache,host_avail,mem_slab,engine_pool,engine_stored,hyp_rss, hyp_tot" > $OUTFILE

    echo "Ready. Press [ENTER] to capture T=0 and detach to background..."
    read dummy
    START_TIME=$(awk '{print $1}' /proc/uptime)

    (
        while true; do
            NOW=$(awk '{print $1}' /proc/uptime)
            T_REL=$(awk "BEGIN {printf \"%.2f\", $NOW - $START_TIME}")

            # Execute 'free' once and map column 2(Total), 3(Used), 4(Free), 6(Buff/Cache), 7(Available)
            eval $(free | awk '/^Mem:/ {printf "H_TOT=%s; H_USE=%s; H_FRE=%s; H_BUF=%s; H_AVL=%s", $2, $3, $4, $6, $7}')

            MEM_SLAB=$(awk '/Slab/ {print $2}' /proc/meminfo)

            HYP_PID=$(pgrep "$4" | head -n 1)
            if [ -n "$HYP_PID" ]; then
                HYP_RSS=$(awk '/VmRSS/ {print $2}' /proc/$HYP_PID/status 2>/dev/null || echo 0)
                HYP_TOT=$(awk '/VmSize/ {print $2}' /proc/$HYP_PID/status 2>/dev/null || echo 0)
            else
                HYP_RSS=0
            fi

            if [ "$3" = "zswap" ]; then
                ENG_POOL=$(cat /sys/kernel/debug/zswap/pool_total_size 2>/dev/null || echo 0)
                ENG_STORED=$(cat /sys/kernel/debug/zswap/stored_pages 2>/dev/null || echo 0)
            else
                ZSTAT=$(cat /sys/block/zram0/mm_stat 2>/dev/null || echo "0 0 0 0 0")
                ENG_STORED=$(echo $ZSTAT | awk '{print $1}')
                ENG_POOL=$(echo $ZSTAT | awk '{print $3}')
            fi

            echo "$T_REL,$H_TOT,$H_USE,$H_FRE,$H_BUF,$H_AVL,$MEM_SLAB,$ENG_POOL,$ENG_STORED,$HYP_RSS, $HYP_TOT" >> $OUTFILE
            sleep 1
        done
    ) >/dev/null 2>&1 &

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
