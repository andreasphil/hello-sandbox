# Sandbox

A container for coding agents working on this project. The agent runs in its own VM, can't read your home directory and can't make commits. Its goal is to protect against accidental damage, secret leakage, and similar risks when developing in a trusted codebase.

It's based on [hello-sandbox](https://github.com/andreasphil/hello-sandbox). The [project-specific changes](#project-specific-changes) section lists what's different for this project.

## Requirements

- [container](https://github.com/apple/container)
- [mise](https://mise.jdx.dev)
- [jq](https://jqlang.org/)

## Usage

From this folder, or from the project root with `mise -C sandbox run <task>`:

```sh
mise run build     # build the image
mise run create    # create and start the container
mise run claude    # start Claude Code in auto mode; shift+tab switches to bypass
mise run stop      # stop the container, keeps its state
mise run start     # start it again
```

`mise task ls` lists all tasks. Run `mise run <task> --help` to get additional information and parameters.

When you first start Claude, you'll be asked to login. All sandboxes share the login. The data is stored on the host at `~/.local/share/sandbox-claude`.

To see if everything works, ask the agent to start the dev servers. You should then be able to access your application at `http://localhost:<port>`.

## What changes need what

| You changed…                                                            | Run                  |
| ----------------------------------------------------------------------- | -------------------- |
| `Dockerfile`, `entrypoint.sh`, `mise.sandbox.toml`, `CLAUDE.sandbox.md` | `build` + `recreate` |
| Ports, volumes, resources or the `create` task in `mise.toml`           | `recreate`           |
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

Some notes:

- The host enforces read-only mounts. Even root in the VM can't write to `.git`.
- The agent sees everything in the project folder. Keep secrets out of it.
- Every sandbox can read the Claude login in the shared Claude folder.
- The host still runs files the sandbox can change, including `package.json` scripts, git hooks config, and build files. Review changes to them before you run anything on the host.

## What persists

| What                                              | `stop`/`start` | `recreate` | `destroy` |
| ------------------------------------------------- | -------------- | ---------- | --------- |
| Container filesystem: installed packages, history | kept           | lost       | lost      |
| This sandbox's volumes: `node_modules`, browsers  | kept           | kept       | lost      |
| Shared Claude folder                              | kept           | kept       | kept      |
| Project                                           | kept           | kept       | kept      |

## Project-specific changes

(tbd. while creating the sandbox)
