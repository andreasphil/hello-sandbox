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

Every project gets its own sandbox, based on the template in this repo:

- [`sandbox/`](./sandbox) is the boilerplate. It has everything a simple Node project needs, and shows how I like to set up things. Check the [README](./sandbox/README.md) for how to use it.

- [`skill/`](./skill) is a Claude Code skill that builds a sandbox for a project from the boilerplate. It looks around the project, asks about anything it can't figure out on its own, then adapts a copy of the boilerplate and tests it.

The agent writes and maintains its [references](./skill/references), which collect what it learned while building sandboxes for more advanced setups.

What you get out of the box:

- Apple's [container](https://github.com/apple/container) as the engine, so [every sandbox is its own VM](https://github.com/apple/container/blob/main/docs/technical-overview.md#how-does-container-run-my-container)
- Ubuntu with [mise](https://mise.jdx.dev), [Node](https://nodejs.org/en), [pnpm](https://pnpm.io/), [Claude Code](https://claude.com/product/claude-code), [Playwright CLI](https://github.com/microsoft/playwright-cli) with its skill, and Chromium dependencies
- The project mounted at the same path as on the host
- Read-only `.git` and no pushing (unless you add your credentials to the sandbox)
- Volumes for `node_modules`, browsers, and other package dependencies
- Shared Claude login between all sandboxes
- Sandbox-specific `CLAUDE.md` instructions in addition to the project's own
- A consistent set of tasks for managing the sandbox

## Requirements

- [container](https://github.com/apple/container)
- [mise](https://mise.jdx.dev)
- [jq](https://jqlang.org/)

## Usage

Link the skill:

```sh
ln -s ~/path/to/hello-sandbox/skill ~/.claude/skills/project-sandbox
```

Then ask Claude to set up a sandbox in a project. By default, the files will be placed in `sandbox/`, and added to your local Git excludes. When it's done:

```sh
cd sandbox
mise run build     # build the image
mise run create    # create the container
mise run claude    # launch Claude inside the container
```


## Status

- [x] core runtimes and package managers: Node and pnpm via mise
- [x] [Claude Code](https://claude.com/product/claude-code) with one login shared across sandboxes
- [x] restricted `developer` account to run agents with generous permissions
- [x] [Playwright](https://playwright.dev/) system dependencies pre-installed, browsers on demand
- [x] [Playwright CLI](https://github.com/microsoft/playwright-cli) so the agent can click through the app
- [x] frontend dev servers and unit tests, reachable from the host
- [x] container-local agent instructions that explain the sandbox's limits
- [x] separate `node_modules` from the host, so `pnpm install` doesn't conflict
- [x] Apple's [container](https://github.com/apple/container) as the engine
- [x] Docker services and [Testcontainers](https://testcontainers.com/) inside the sandbox ([reference](./skill/references/docker.md))
- [x] Java and Gradle ([reference](./skill/references/java-gradle.md))
- [ ] [Context7](https://context7.com/) for docs lookup
- [ ] other agents such as [OpenCode](https://opencode.ai/) with its web interface, and [Pi](https://pi.dev/)
- [ ] restricting network egress

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
