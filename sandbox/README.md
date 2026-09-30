# Sandbox

A container for coding agents working on this project. Think of it as a helmet against accidents. The agent runs in its own VM, can't read your home directory and can't make commits. It won't stop a determined attacker, and it doesn't try to.

It's based on [hello-sandbox](https://github.com/andreasphil/hello-sandbox). The [project-specific changes](#project-specific-changes) section lists what's different for this project.

## Requirements

- Apple [container](https://github.com/apple/container) with the system service running. Start it with `container system start`.
- [mise](https://mise.jdx.dev) and `jq` on the host

## Usage

Run these from this folder, or from the project root with `mise -C sandbox run <task>`:

```sh
mise run build     # build the image
mise run create    # create and start the container
mise run claude    # start Claude Code in auto mode; shift+tab switches to bypass
mise run shell     # open a shell as the developer user; --root for root
mise run stop      # stop the container, keeps its state
mise run start     # start it again
mise run recreate  # replace the container with a fresh one from the image, keeps volumes
mise run destroy   # delete the container and its volumes, keeps the shared Claude login
```

Log in the first time you start Claude. All sandboxes share the login.

The agent starts dev servers itself. Open them at `http://localhost:<port>` on the host. `SANDBOX_PORTS` in [mise.toml](./mise.toml) lists the published ports, which only listen on 127.0.0.1. If something on the host already uses one of these ports, the two will conflict.

## What changes need what

| You changed…                                                            | Run                  |
| ----------------------------------------------------------------------- | -------------------- |
| `Dockerfile`, `entrypoint.sh`, `mise.sandbox.toml`, `CLAUDE.sandbox.md` | `build` + `recreate` |
| Ports, volumes or resources in `mise.toml`                              | `recreate`           |
| Nothing (first time or after `destroy`)                                 | `build` + `create`   |

## What the sandbox can access

| Path                | Access              | Notes                                                      |
| ------------------- | ------------------- | ---------------------------------------------------------- |
| The project         | read/write          | mounted at the same path as on the host                    |
| `.git`              | read-only           | commit on the host                                         |
| `node_modules`      | volume              | Linux binaries; the host's `node_modules` stay as they are |
| Playwright browsers | volume              |                                                            |
| `~/.claude`         | host folder         | `SANDBOX_CLAUDE_DIR`, shared by all sandboxes              |
| Rest of the host    | none                | `create` copies in your global gitignore; nothing else     |
| Network             | unrestricted egress |                                                            |

- **The host enforces read-only mounts.** Even root in the VM can't write to `.git`.
- **The host still runs files the sandbox can change.** `package.json` scripts, git hooks config and build files are the obvious ones. Review changes to them before you run anything on the host.
- **The agent sees everything in the project folder.** Keep secrets out of it.
- **Every sandbox can read the Claude login** in the shared Claude folder. That's the price of logging in once.

## What persists

| What                                              | `stop`/`start` | `recreate` | `destroy` |
| ------------------------------------------------- | -------------- | ---------- | --------- |
| Container filesystem: installed packages, history | kept           | lost       | lost      |
| This sandbox's volumes: `node_modules`, browsers  | kept           | kept       | lost      |
| Shared Claude folder                              | kept           | kept       | kept      |
| Project                                           | kept           | kept       | kept      |

## Project-specific changes

None yet.
