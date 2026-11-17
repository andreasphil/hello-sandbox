# Hello Sandbox 🪏

**Experimenting with sandboxing coding agents through containers**

> [!CAUTION]
>
> Work in progress. Container-based sandboxing has [limitations](https://www.luiscardoso.dev/blog/sandboxes-for-ai#:~:text=Where%20containers%20fail).

The idea:

- ⚖️ Finding a pragmatic balance between productivity and safety
- 🧯 Basic protection against common risks during development in trusted codebases
- ⚠️ Not intended to go full YOLO or provide robust protection against targeted attacks
- 🍱 An environment for agents that complements your local dev setup instead of replacing it
- 🪶 Simple and understandable; complexity is a risk in and of itself

## How it works

Each project gets its own sandbox in the form of a container.

All sandboxes share a minimal image with Ubuntu, a few system-level dependencies, Docker and prerequisites for Playwright (both optional), and [mise](https://mise.jdx.dev/). Inside each sandbox, mise manages any additional tools.

The template consists of:

| File                | Description                                                    | Shared? |
| ------------------- | -------------------------------------------------------------- | ------- |
| `AGENTS.sandbox.md` | Sandbox-specific instructions, copied to `~/.claude/CLAUDE.md` | no      |
| `Dockerfile`        | Builds the shared image for all sandboxes                      | yes     |
| `entrypoint.sh`     | Shared entrypoint for all sandboxes                            | yes     |
| `mise.toml`         | Host-side configuration and tasks for managing a sandbox       | no      |
| `mise.sandbox.toml` | Global tools, tasks, and setup inside the sandbox              | no      |

What you get out of the box:

- Apple's [container](https://github.com/apple/container) as the engine, so [every sandbox is its own VM](https://github.com/apple/container/blob/main/docs/technical-overview.md#how-does-container-run-my-container)
- Ubuntu with [mise](https://mise.jdx.dev), [Claude Code](https://claude.com/product/claude-code), [Docker](https://www.docker.com/), and Chromium dependencies
- The project mounted at the same path as on the host
- Read-only `.git` and no pushing (unless you add your credentials to the sandbox)
- Persistent volumes for `home` and Docker images, with the option to add more
- Sandbox-specific `CLAUDE.md` instructions in addition to the project's own
- Claude Code credentials from 1Password
- A consistent set of tasks for managing the sandbox

## Requirements

- [container](https://github.com/apple/container)
- [mise](https://mise.jdx.dev)

## Usage

To get started, create a `sandbox` directory in your project and copy the template into it. Then customize the template to your needs.

> [!TIP]
>
> Look for `FIXME:` comments to find the places you'll most likely want to customize.

First, check the `Dockerfile`. It's the shared foundation for all your sandboxes, so add or remove anything you always (or never) need. Then build the image:

```bash
mise run build
```

Next, create and start the sandbox:

```bash
mise run create
```

This creates the container and sets up port bindings and mounts. It then installs the tools from your project's `mise.toml` and bootstraps the sandbox with the `sandbox:setup` task. The sandbox ignores `mise.local.toml`. Once that's done:

```bash
mise run stop       # stop the sandbox
mise run start      # start the sandbox again
mise run claude     # start a Claude session in the sandbox
mise run shell      # open an interactive shell in the sandbox
mise run build      # rebuild the image after changes to the Dockerfile or entrypoint
mise run recreate   # recreate the sandbox after configuration changes (volumes persist)
mise run destroy    # delete the sandbox and its volumes
```

## Alternatives considered

- **Built-in agent permissions:** Works well enough for my use case, but requires a lot of manual oversight... tedious and can lead to decision fatigue. Some models also tend to write lots of scripts to get things done, which adds mental overhead when approving tool calls.

- **YOLO:** Some people say that [everything else is security theater anyway](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/#toc_13). Tempting, but surely _any_ protection is better than no protection at all.

- **Claude Code's built-in [sandbox](https://code.claude.com/docs/en/sandboxing):** Promising, but doesn't allow much control over the sandbox. Unfortunately, many things the agent needs to do also don't work inside it, most notably E2E tests.

- **`sandbox-exec` and friends ([Agent Safehouse](https://agent-safehouse.dev/), [Anthropic Sandbox Runtime](https://github.com/anthropic-experimental/sandbox-runtime)):** The tech behind Claude Code's built-in sandbox. Using it directly would offer more configuration flexibility, but the resulting rulesets are huge, and I find them hard to understand and manage.

- **[Shuru](https://shuru.run/):** Unless I'm misunderstanding, Shuru is more of a low-level tool for building your own agents. For end users, they provide a skill the agent can use to sandbox its own commands. That's not a decision I want to leave to the agent, though 🤨

- **[Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers):** Pretty much a more user-friendly layer on top of Docker. While I can see the appeal, it adds indirection and extra tooling dependencies that I'd rather avoid.

- **mise [task sandboxing](https://mise.jdx.dev/sandboxing.html):** Experimental support for sandboxing tasks. Since you can run anything as a task, this should also allow sandboxing agents. I don't know if it's meant for complex processes, but worth looking into.

- **[Docker Sandboxes](https://docs.docker.com/ai/sandboxes/):** Interesting option now that it's no longer tied to Docker Desktop. Still at an early, experimental stage, though, and too unreliable for daily use in my testing.

- **[UTM](https://mac.getutm.app/):** Full virtual machine. Certainly works, but running an entire operating system comes with significant performance and setup overhead.

Even more: [coi](https://github.com/mensfeld/code-on-incus) (Code on Incus), [Sprites](https://sprites.dev/), [Zerobox](https://github.com/afshinm/zerobox), [nono](https://nono.sh/)

## Resources

- [A field guide to sandboxes for AI](https://www.luiscardoso.dev/blog/sandboxes-for-ai)
- [Simon Willison on sandboxing](https://simonwillison.net/tags/sandboxing/)
- [Building Pi, and what makes self-modifying software so fascinating](https://www.youtube.com/watch?v=n5f51gtuGHE)
