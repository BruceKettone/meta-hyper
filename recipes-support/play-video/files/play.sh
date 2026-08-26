#!/bin/sh

STREAM=0
DEFAULT_URL="https://filesamples.com/samples/video/mp4/sample_640x360.mp4"
TEMP_FILE="/tmp/downloaded_vid.webm"

# Parse arguments loop
while [ "$#" -gt 0 ]; do
    case "$1" in
        -s|--sync)
            sync-time
            shift
            ;;
        --stream)
            STREAM=1
            shift
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Usage: play [-s|--sync] [--stream] [URL_OR_FILE]"
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

TARGET="$1"
if [ -z "$TARGET" ]; then
    TARGET="$DEFAULT_URL"
fi

case "$TARGET" in
    http://*|https://*)
        if [ "$STREAM" -eq 1 ]; then
            echo "Streaming video directly..."
            exec mpv --vo=x11 --cache=no --no-audio "$TARGET"
        else
            echo "Downloading video to RAM/disk first..."
            rm -f "$TEMP_FILE"

            wget -O "$TEMP_FILE" "$TARGET"
            if [ $? -eq 0 ]; then
                echo "Download complete. Playing video..."
                exec mpv --vo=x11 --no-audio "$TEMP_FILE"
            else
                echo "Error: Download failed."
                exit 1
            fi
        fi
        ;;
    *)
        if [ -f "$TARGET" ]; then
            echo "Playing local file..."
            exec mpv --vo=x11 --no-audio "$TARGET"
        else
            echo "Error: File '$TARGET' not found."
            exit 1
        fi
        ;;
esac
