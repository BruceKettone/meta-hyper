#!/bin/sh
# Usage: standalone-logger start /tmp/run_standalone [none|zram|zswap]
#        standalone-logger stop

COMMAND=$1
OUTFILE="${2}_${3}_metrics.csv"
PIDFILE="/tmp/standalone_logger.pid"

if [ "$COMMAND" = "start" ]; then
    if [ -f "$PIDFILE" ]; then
        echo "Logger is already running!"
        exit 1
    fi

    # Unified Header
    echo "timestamp_rel,mem_total,mem_used,mem_free,mem_buff_cache,mem_avail,anon_pages,engine_pool,engine_stored" > $OUTFILE

    echo "Ready. Press [ENTER] to capture T=0 and detach..."
    read dummy
    START_TIME=$(awk '{print $1}' /proc/uptime)

    (
        while true; do
            NOW=$(awk '{print $1}' /proc/uptime)
            T_REL=$(awk "BEGIN {printf \"%.2f\", $NOW - $START_TIME}")

            # Execute 'free' once
            eval $(free | awk '/^Mem:/ {printf "TOT=%s; USE=%s; FRE=%s; BUF=%s; AVL=%s", $2, $3, $4, $6, $7}')

            # Guest-specific payload metric
            ANON_PAGES=$(awk '/AnonPages/ {print $2}' /proc/meminfo)

            # Handle the three configurations: basic(none), zram, zswap
            if [ "$3" = "zswap" ]; then
                ENG_POOL=$(cat /sys/kernel/debug/zswap/pool_total_size 2>/dev/null || echo 0)
                ENG_STORED=$(cat /sys/kernel/debug/zswap/stored_pages 2>/dev/null || echo 0)
            elif [ "$3" = "zram" ]; then
                ZSTAT=$(cat /sys/block/zram0/mm_stat 2>/dev/null || echo "0 0 0 0 0")
                ENG_STORED=$(echo $ZSTAT | awk '{print $1}')
                ENG_POOL=$(echo $ZSTAT | awk '{print $3}')
            else
                # For the "basic" run, compression metrics are zero
                ENG_POOL=0
                ENG_STORED=0
            fi

            echo "$T_REL,$TOT,$USE,$FRE,$BUF,$AVL,$ANON_PAGES,$ENG_POOL,$ENG_STORED" >> $OUTFILE
            sleep 1
        done
    ) >/dev/null 2>&1 &

    echo $! > $PIDFILE
    echo "Standalone logging detached."

elif [ "$COMMAND" = "stop" ]; then
    if [ -f "$PIDFILE" ]; then
        kill $(cat $PIDFILE)
        rm -f $PIDFILE
        echo "Logging stopped."
    fi
else
    echo "Usage: standalone-logger [start|stop] [outfile_prefix] [none|zram|zswap]"
fi
