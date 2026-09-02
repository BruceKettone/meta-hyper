#!/bin/sh

# Sync time only if -s or --sync is passed
if [ "$1" = "-s" ] || [ "$1" = "--sync" ]; then
    sync-time
    shift
fi

# Set environment variables for software rendering
export WEBKIT_DISABLE_COMPOSITING_MODE=1
export LIBGL_ALWAYS_SOFTWARE=1

# Open the default URL if none was provided
if [ "$#" -eq 0 ]; then
    set -- "https://ismycomputeron.net"
fi

exec surf "$@"
