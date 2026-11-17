#!/bin/bash

set -euo pipefail

for dir in $(findmnt -rn -t ext4 -O rw -o TARGET | grep -vx / | grep -vx /var/lib/docker); do
  chown developer:developer "$dir" # newly created volumes are owned by root
  rmdir "$dir/lost+found" 2>/dev/null || true # lost+found breaks pnpm
done

if [[ ${SANDBOX_DOCKER:-false} == true ]]; then
  mount -o remount,rw /proc/sys
  mkdir -p /sys/fs/cgroup/init
  xargs -rn1 < /sys/fs/cgroup/cgroup.procs > /sys/fs/cgroup/init/cgroup.procs || true
  sed -e 's/ / +/g' -e 's/^/+/' < /sys/fs/cgroup/cgroup.controllers > /sys/fs/cgroup/cgroup.subtree_control
  mount -t tmpfs tmpfs /run

  exec dockerd --log-level warn
fi

exec sleep infinity
