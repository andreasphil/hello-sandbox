# Hello Sandbox 🪏

**Experimenting with sandboxing coding agents through Docker**

> [!CAUTION]
>
> Work in progress. Docker-based sandboxing has [limitations](https://www.luiscardoso.dev/blog/sandboxes-for-ai#:~:text=Where%20containers%20fail).

The idea:

- ⚖️ Finding a pragmatic balance between productivity and safety
- 🧯 Basic protection against common risks during development in trusted codebases
- ⚠️ Not intended to go full YOLO or provide robust protection against targeted attacks
- 🍱 An environment for agents to operate in to complement your local dev setup, not replace it
- 🪶 Simple and understandable; complexity is a risk in and of itself

## Status

- [x] core runtimes and package managers: Node 24, PNPM 10, Java 21
- [x] easy installation of additional packages + task management through [Mise](https://mise.jdx.dev/)
- [x] supports [Claude Code](https://claude.com/product/claude-code) with configuration mounted from the host for persistence across sessions
- [x] restricted `developer` account to run agents with generous permissions
- [x] [Playwright](https://playwright.dev/) + Chromium pre-installed for E2E tests
- [x] runs frontend dev servers and unit tests
- [x] runs backend unit tests with Java
- [x] simple Mise-based setup
- [ ] directly launch the agent when running the container instead of SSH-ing into it
- [ ] container-local agent instructions with limitations/specifics of the sandbox
- [ ] running or connecting to Docker services (required for running backend)
- [ ] [multiplexer](https://zellij.dev/) for running backend and frontend (required for E2E tests)
- [ ] ability to run backend integration tests that require [Testcontainers](https://testcontainers.com/)
- [ ] [Playwright CLI](https://github.com/microsoft/playwright-cli) integration to allow the agent to explore the app
- [ ] [Context7](https://context7.com/) integration for easy docs access
- [ ] [`--cap-drop=ALL`](https://docs.docker.com/engine/containers/run/#runtime-privilege-and-linux-capabilities) and [`no-new-privileges`](https://docs.docker.com/reference/cli/docker/container/run/#security-opt)

Also considering:

- [ ] separation from the project on the host system, e.g. so `pnpm install` doesn't conflict
- [ ] using Apple's [container](https://github.com/apple/container) as the engine—this should provide some [security benefits](https://4sysops.com/archives/apple-container-vs-docker-desktop/#:~:text=or%20Macvlan%20drivers.-,Security%20and%20isolation,-Apple%E2%80%99s%20container%20tool)
- [ ] preparing the Gradle wrapper during the image build to speed up Java tasks
- [ ] alternative agents such as [OpenCode](https://opencode.ai/) (+ web interface) and [Pi](https://pi.dev/)
- [ ] better ways of installing project-specific dependencies
- [ ] reusability accross projects in general

## Requirements

- [Docker](https://docker.com)
- [mise](https://mise.jdx.dev)

## Usage

Build the image:

```bash
mise run build
```

Start a session:

```bash
mise run dev <path/to/project>

# or get more information:
mise run dev --help
```

When you run `dev` for the first time, an empty Claude folder and config JSON will be created in the current folder. You'll need to login to Claude once inside the container; after that, your session and settings should be saved to the host system.

## Alternatives considered

- **Built-in agent permissions:** Works decently well for my use case, but requires a lot of manual oversight, which is tedious and can lead to decision fatigue. Some models also tend to write a lot of scripts to get things done, which adds a lot of mental overhead when approving tool calls.

- **YOLO:** Some people say that [everything else is security theater anyway](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/#toc_13). Tempting, but surely *any* protection is better than no protection at all.

- **Claude Code's built-in [sandbox](https://code.claude.com/docs/en/sandboxing):** Promising, but doesn't allow much control over the sandbox, and unfortunately many of the things the agent needs to do don't work from within the sandbox (most notably E2E tests).

- **`sandbox-exec` and friends ([Agent Safehouse](https://agent-safehouse.dev/), [Anthropic Sandbox Runtime](https://github.com/anthropic-experimental/sandbox-runtime)):** The tech behind Claude Code's built-in sandbox—using it directly would offer more flexibility for configuration, but the resulting rulesets are huge and I find them hard to understand and manage.

- **[Shuru](https://shuru.run/):** Unless I'm misunderstanding, Shuru seems to be more of a low-level tool to be used when building your own agents. For end users, they provide a skill that the agent can use for sandboxing its own commands. That's not a decision I want to leave to the agent though 🤨

- **[Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers):** Pretty much a more user-friendly layer on top of Docker. While I can see the appeal, it adds some indirection and additional tooling dependencies that I'd rather avoid.

- **Mise [task sandboxing](https://mise.jdx.dev/sandboxing.html):** Experimental support for sandboxing tasks. Since you can run anything as a task, this should also allow sandboxing agents. I don't know if it's intended to be used with complex processes though, but worth evaluating.

- **[Docker Sandboxes](https://docs.docker.com/ai/sandboxes/):** Interesting option now that it's no longer tied to Docker Desktop. Early experimental stage for now though; too unreliable for daily use in my testing.

- **[utm](https://mac.getutm.app/):** Full virtual machine. Certainly works, but comes with significant performance and setup overhead from running an entire operating system.

Even more: [coi](https://github.com/mensfeld/code-on-incus) (Code on Incus), [Sprites](https://sprites.dev/), [Zerobox](https://github.com/afshinm/zerobox), [nono](https://nono.sh/)

## Resources

- [A field guide to sandboxes for AI](https://www.luiscardoso.dev/blog/sandboxes-for-ai)
- [Simon Willison on sandboxing](https://simonwillison.net/tags/sandboxing/)
