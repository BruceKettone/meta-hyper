#!/bin/sh
echo "Syncing time with pool.ntp.org..."

while ! ntpd -q -n -p "pool.ntp.org"; do
    echo "Network not ready, retrying time sync in 1 second..."
    sleep 1
done

echo "Time synced successfully!"
