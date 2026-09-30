#!/bin/bash
# Runs as root on every container start, then idles. All work happens in
# `container exec` sessions.
set -euo pipefail

# volumes are the writable ext4 mounts other than the root filesystem. new
# ones are root-owned, so hand them to the developer. lost+found breaks pnpm
# when it scans node_modules.
for dir in $(findmnt -rn -t ext4 -O rw -o TARGET | grep -vx /); do
  chown developer:developer "$dir"
  rmdir "$dir/lost+found" 2>/dev/null || true
done

exec sleep infinity
