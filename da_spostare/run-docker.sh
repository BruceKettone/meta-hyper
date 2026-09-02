#!/bin/bash

# This assumes you place this script in the root of the "yoctoDocker" directory.
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Dynamic Audio Socket Resolution ---
# Gets the current user's UID
USER_UID=$(id -u)
PULSE_SOCKET="/run/user/${USER_UID}/pulse/native"

echo "=== Building Docker Image ==="
docker build -t yocto-ubuntu-test .

# --- 1. Allow X11 Docker Forwarding ---
xhost +local:docker

# --- 2. Clean up old container ---
echo "Removing old container (if any)..."
docker container rm -f yocto-build-env 2>/dev/null || true

# --- 3. Run Docker ---
echo "Starting Yocto Docker Environment..."
docker run -it --rm --name yocto-build-env-test \
  --publish 5900:5900 \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "${PULSE_SOCKET}:/tmp/pulse-socket" \
  -v "${WORKSPACE_DIR}:/home/yoctouser/workspace" \
  yocto-ubuntu-test
