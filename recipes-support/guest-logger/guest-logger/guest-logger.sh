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

    echo "timestamp_rel,guest_total,guest_used,guest_free,guest_buff_cache,guest_avail,anon_pages" > $OUTFILE

    echo "Ready. Press [ENTER] to capture T=0 and detach to background..."
    read dummy
    START_TIME=$(awk '{print $1}' /proc/uptime)

    (
        while true; do
            NOW=$(awk '{print $1}' /proc/uptime)
            T_REL=$(awk "BEGIN {printf \"%.2f\", $NOW - $START_TIME}")

            # Execute 'free' and map columns
            eval $(free | awk '/^Mem:/ {printf "G_TOT=%s; G_USE=%s; G_FRE=%s; G_BUF=%s; G_AVL=%s", $2, $3, $4, $6, $7}')

            ANON_PAGES=$(awk '/AnonPages/ {print $2}' /proc/meminfo)

            echo "$T_REL,$G_TOT,$G_USE,$G_FRE,$G_BUF,$G_AVL,$ANON_PAGES" >> $OUTFILE
            sleep 1
        done
    ) >/dev/null 2>&1 &

    echo $! > $PIDFILE
    echo "Logging detached. Terminal is yours. Run 'guest-logger stop' to end."

elif [ "$COMMAND" = "stop" ]; then
    if [ -f "$PIDFILE" ]; then
        kill $(cat $PIDFILE)
        rm -f $PIDFILE
        echo "Logging safely stopped."
    else
        echo "No logger process found."
    fi
else
    echo "Usage: guest-logger [start|stop] [outfile_prefix]"
fi
