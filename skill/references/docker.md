# Docker inside the sandbox

Applies when the project uses Docker, Docker Compose or Testcontainers, for example for databases, search engines or integration tests.

## Options

1. **Run dockerd inside the sandbox.** Works with Apple container, with the setup below. Everything stays in the sandbox's VM. This is the default choice.
2. **Forward the host's Docker socket.** Easy, but whoever can use the socket can mount any host path into a container. That cancels out the sandbox. Don't do this.
3. **Run Docker things on the host.** The fallback if option 1 fails. The sandbox then reaches the services through the host.

## Setup for dockerd inside the sandbox

**Dockerfile:**

- Install `docker.io` and `docker-compose-v2` with apt.
- Add the developer to the `docker` group: `useradd -m -u 1000 -G docker ...`. That makes the developer root-equivalent inside the VM, which is fine: the VM boundary and the mounts protect the host.

**`create` task:**

- Add `--cap-add ALL`. dockerd needs, among others, `NET_ADMIN` for iptables, `SYS_ADMIN` for mounts, and permission to bind-mount network namespaces. With fewer capabilities it fails step by step. Every Apple container is its own VM, so this means root in the VM, not on the Mac.

**Entrypoint** (runs as root, in this order):

```bash
# dockerd needs to enable IP forwarding, but /proc/sys is read-only by default
mount -o remount,rw /proc/sys

# with processes in the root cgroup, dockerd can only create threaded cgroups,
# and container stop fails on those. move everything into a child cgroup and
# enable all controllers, like the docker:dind image does.
mkdir -p /sys/fs/cgroup/init
xargs -rn1 < /sys/fs/cgroup/cgroup.procs > /sys/fs/cgroup/init/cgroup.procs || true
sed -e 's/ / +/g' -e 's/^/+/' < /sys/fs/cgroup/cgroup.controllers \
  > /sys/fs/cgroup/cgroup.subtree_control

# /run lives on the persistent disk, so pid files would survive an unclean
# stop and make dockerd think it's already running. a tmpfs starts empty.
mount -t tmpfs tmpfs /run

exec dockerd --log-level warn
```

`dockerd` replaces `sleep infinity` as the main process. Keep the volume `chown` loop before it.

**`stop` task:** give dockerd time to stop its containers: `container stop --time 30 "$SANDBOX_NAME"`. The default 5 seconds isn't enough for services like OpenSearch.

## Why each step is there

- **`/proc/sys` remount:** without it, dockerd fails with `open /proc/sys/net/ipv4/ip_forward: read-only file system`.
- **cgroup move:** without it, dockerd creates a `docker` cgroup of type `threaded`. The kernel rejects `cgroup.kill` on threaded cgroups, so `container stop` fails with `errno 95: failed to write to /sys/fs/cgroup/.../docker/cgroup.kill` whenever Docker containers are running. The container then hangs in a half-stopped state.
- **tmpfs on `/run`:** after a failed stop, `/run/docker.pid` stays on disk. On the next start, dockerd finds PID 2 (which is now dockerd itself) and refuses to start with `process with PID 2 is still running`. The container then won't start at all.
- Test stop and start **with Docker containers running**. Everything looks fine with an idle dockerd.

## Services and ports

- Compose services with `restart: unless-stopped` come back after `container start` on their own.
- Publish the service ports the user wants to open on the host in `SANDBOX_PORTS`. Services inside the sandbox publish on `0.0.0.0`, so the forwarding works.
- Images live in the container's filesystem. They survive `stop`/`start`, but `recreate` downloads them again.

Tell the agent in `CLAUDE.sandbox.md` that Docker is available, and how to start the services, like `docker compose up -d --wait` in the project root. The boilerplate's `CLAUDE.sandbox.md` says that nothing is running at the start. That's no longer true for services with `restart: unless-stopped`, so reword it: dev servers aren't running, services may be, and the start commands are safe either way.

## Testcontainers

Works without extra setup. Tests run in the same VM as dockerd, so mapped ports on `localhost` work, fixed host ports too.

Integration tests are CPU-heavy. A dev OpenSearch running at the same time made them 4 times slower in one project. Stop dev services before long test runs, or give the sandbox more CPUs.
