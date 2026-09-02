#!/bin/bash
set -e

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Building Docker Image ==="
docker build -t yocto-ubuntu-test .

# --- Clean up old container ---
echo "Removing old container (if any)..."
docker container rm -f yocto-build-env-test 2>/dev/null || true

# Ensure local build directory exists for mounting
mkdir -p "${WORKSPACE_DIR}/build"

# --- Run Docker ---
echo "Starting Yocto Docker Environment..."
docker run -it --rm --name yocto-build-env-test \
  --publish 4444:4444 \
  --publish 5900:5900 \
  -v "${WORKSPACE_DIR}/build:/home/yoctouser/workspace/build" \
  yocto-ubuntu-test
