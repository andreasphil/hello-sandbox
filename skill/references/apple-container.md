# Apple container

Facts and quirks of Apple's `container` CLI, found while building sandboxes. Tested with version 1.5.

## Basics

- Every container is its own lightweight VM with its own kernel. Root in the container is root in that VM, not on the Mac. This is why the sandbox can hand out Linux capabilities that would be dangerous with Docker Desktop's shared kernel.
- A container keeps its filesystem across `stop` and `start`. Only `delete` loses it. The boilerplate uses one long-lived container per project, not `--rm`.
- Mounts, ports, capabilities and resources are fixed when the container is created. Changing them means `recreate`.
- The container service must be running: `container system start`. Without it, every command fails with an XPC error.
- Inside Claude Code's own Bash sandbox, `container` commands fail with "Operation not permitted" or XPC errors. Run them outside of it.

## Mounts and volumes

- **Bind mounts must be directories.** Mounting a single file fails with "is not a directory". Copy single files in with `container cp` after `container run`. The boilerplate does this for the global gitignore.
- **Files in bind mounts look root-owned inside the container.** Writes from any user end up owned by the host user. There's no uid mapping to set up. git refuses to work with root-owned repos, so the boilerplate sets `safe.directory '*'`.
- **Read-only bind mounts are enforced by the host.** Even root in the VM can't write through them, not even after `mount -o remount,rw`.
- **Don't remount bind mounts.** All bind mounts share one virtiofs superblock. `mount -o remount,ro` on one of them makes every bind mount read-only until the next restart.
- **Nested mounts work.** A read-only mount of `.git` inside a read-write project mount, or a volume over `node_modules`, behave as expected.
- **Named volumes are ext4 block devices.** A new volume is root-owned and contains `lost+found`. The entrypoint hands volumes to the developer and removes `lost+found`, which otherwise breaks pnpm.
- **`container run` creates missing named volumes itself.** No need to create them beforehand. Host folders for bind mounts must exist, though.
- **A volume can only be attached to one running container at a time.** A second container using it fails to start with `The storage device attachment is invalid`. To share data between sandboxes that run at the same time, like the Claude login, bind-mount a folder from the host instead. Bind mounts work in several containers at once.
- **Volumes can't be deleted while a container uses them,** even a stopped one. Delete the container first.

## Networking

- Published ports forward to the container's network interface, not to its loopback. A server bound to `127.0.0.1` inside the container isn't reachable from the host. See `dev-servers.md`.
- Publish to `127.0.0.1` on the host (`--publish 127.0.0.1:3000:3000`), so the ports aren't reachable from the network.
- The host can also reach a container directly by its IP (`container ls` shows it), without publishing. IPs change between starts, so published ports are more practical.

## Processes and exec

- `container exec` inherits the working directory set with `--workdir` on `container run`.
- `--env NAME` without a value passes the variable from the calling shell. Use this for secrets, so they don't show up in the process list. See `secrets-1password.md`.
- `--init` runs a small init as PID 1, which forwards signals and reaps zombies. The boilerplate's entrypoint then idles with `sleep infinity`.
- `container stop` waits 5 seconds by default before it kills the container. Give processes that shut down slowly more time with `--time`.
- File changes made on the host don't trigger inotify events inside the container. Watchers only see changes made inside it. Hot reload works for the agent's edits, not for the user's.

## `container machine`

`container machine` looks like a fit for persistent environments, but don't use it for sandboxes:

- Its only filesystem option is `home-mount`, which mounts the whole home directory (`ro` or `rw`), `~/.ssh` included, or nothing at all (`none`).
- There are no options for custom mounts or published ports.
- The image needs a real init at `/sbin/init`, like systemd. Plain Ubuntu doesn't boot.
- `container machine run` splits arguments on spaces again, so quoted arguments break. Pipe a script into `bash -s` instead.

A plain container persists just as well, and it has precise mounts and ports. The sandbox doesn't need systemd.

## Inspecting state

- `container inspect <name>` returns JSON. `.[0].status.state` is `running` or `stopped`. `.[0].configuration.image.descriptor.digest` is the image the container was created from.
- `container image inspect <name>` returns JSON. `.[0].configuration.descriptor.digest` is the current image digest. If it differs from the container's, the container runs an older image and needs `recreate`.
