---
name: project-sandbox
description: Build a bespoke sandbox container for a project, starting from the hello-sandbox boilerplate. Use when the user asks to set up, create or build a sandbox, a sandboxed dev environment, or a container for coding agents for a project, or to adapt an existing project sandbox to new needs (Java, Docker, secrets, extra services).
---

# Project sandbox

Build a sandbox for one project: a container the agent works in with generous permissions, while the host stays protected from accidents. Every project gets its own copy. Don't build an abstraction. The boilerplate in `../sandbox`, next to this skill's folder, is the starting point and the reference, and you adapt the copy to what the project needs.

## Principles

- **A helmet, not a vault.** Protect against accidents: no access to the home directory, no commits, no credentials, its own VM. Don't try to stop a determined attacker.
- **Minimal permissions for the sandbox, maximum permissions inside it.** The agent should be able to install, build, test and run everything the project needs without asking.
- **Easy to understand.** The user must be able to read every file and know what it does. Prefer explicit over clever. Complexity is a risk in itself.
- **Everything known in code.** Anything needed every time goes in the Dockerfile or `mise.toml`, so `destroy` + `build` + `create` recreates the sandbox.
- **Same task names everywhere.** `build`, `create`, `start`, `stop`, `shell`, `claude`, `recreate`, `destroy`. Don't rename or remove them. Add tasks only if the host needs something new.

## What the boilerplate gives you

Read all files in the boilerplate before you start. In short:

- Ubuntu with mise, Node, pnpm, Claude Code, `playwright-cli`, and the system libraries for Chromium
- The `playwright-cli` skill in `/etc/claude-code/.claude/skills`, Claude's managed skills folder. Skills for other tools go there too.
- The project mounted at the same path as on the host. `.git` is mounted read-only.
- Volumes for `node_modules` and Playwright browsers
- One Claude config folder on the host (`~/.local/share/sandbox-claude`), shared by all sandboxes, so the user logs in once
- The pnpm store inside the container, never next to the project
- The project's mise config trusted inside the container
- `CLAUDE.sandbox.md`, loaded as managed instructions on top of the project's `CLAUDE.md`
- Host tasks in `mise.toml`, configured through the `SANDBOX_*` variables at the top

## Process

### 1. Survey the project

Look before you ask. Find out:

- Languages, runtimes and package managers, and where their versions are defined
- Every `node_modules` location: workspaces, sub-packages, separate apps
- Dev servers, their ports, and how they bind to a host
- Test suites: unit, E2E, integration, and what each one needs to run
- Docker or Compose files, Testcontainers, and other services the project starts
- Private registries, tokens and other credentials used by builds or installs
- Symlinks in the project that point outside it (`find . -maxdepth 2 -type l`)
- mise files in the project, including gitignored `mise.local.toml`, and whether they contain host-specific settings
- Git hooks (lefthook, husky) and what they run
- The project's `CLAUDE.md` or `AGENTS.md`, and instructions in it that conflict with a sandbox, such as "ask the user to start the dev server"

Then read the references that match what you found:

| If the project has…                                       | Read                                       |
| --------------------------------------------------------- | ------------------------------------------ |
| Anything (always read this)                               | `references/apple-container.md`            |
| Anything (always read this)                               | `references/mise.md`                       |
| Dev servers or services the user opens on the host        | `references/dev-servers.md`                |
| More than one `node_modules` folder                       | `references/multiple-node-modules.md`      |
| Node or pnpm versions in `package.json`, Playwright tests | `references/versions-from-package-json.md` |
| Playwright E2E tests                                      | `references/playwright-e2e.md`             |
| Host-specific settings in the project's mise files        | `references/host-mise-config.md`           |
| Symlinks to files outside the project                     | `references/symlinked-config.md`           |
| Docker, Compose or Testcontainers                         | `references/docker.md`                     |
| Java, Gradle or Maven                                     | `references/java-gradle.md`                |
| Credentials needed for install, build or tests            | `references/secrets-1password.md`          |

### 2. Ask the user, once, before you build

Ask everything you can't find out yourself in one round of questions. Suggest answers from your survey. Typical questions:

- **Location.** The default is `sandbox/` in the project, excluded via `.git/info/exclude`. Does this project need something else, like a folder outside the project with a symlink? See `references/symlinked-config.md`.
- **Ports.** Which dev servers and services does the user want to open on the host? Suggest the ones you found.
- **Credentials.** Which ones does the build need, and what are their 1Password references? Never ask for the secret itself.
- **Checks.** Which checks must work in the sandbox: unit tests, typecheck, lint, E2E, integration tests? Suggest the ones you found. If some are hard, like Docker, offer to run them on the host instead.
- **Linked files.** If the project symlinks to personal files outside it, may the sandbox mount the target folder read-only? List what else is in that folder.
- **Things outside the project.** Does the project need sibling repos, shared config or anything else from the host?

Don't ask about things the boilerplate already decides: read-only `.git`, separate `node_modules`, the shared Claude folder, the task names, auto permission mode. Mention them so the user can object.

### 3. Copy and adapt

1. Copy the boilerplate into the chosen location.
2. Add `sandbox` (no trailing slash, so it also matches a symlink) to `.git/info/exclude`.
3. Run `mise trust` in the new folder.
4. Set the versions in `mise.sandbox.toml` to what the project uses on the host.
5. Set `SANDBOX_PORTS`, `SANDBOX_VOLUMES`, `SANDBOX_CPUS` and `SANDBOX_MEMORY` in `mise.toml`.
6. Apply what the matching references describe.
7. Add project-specific instructions to `CLAUDE.sandbox.md`: how to start servers and services, and which project instructions don't apply in the sandbox.
8. Describe every change from the boilerplate under "Project-specific changes" in `sandbox/README.md`.

Keep changes small and explained with comments. If something from a reference doesn't fit this project, adapt it and say why.

### 4. Build and validate

Commands that talk to the `container` service (build, run, exec, and so on) fail inside Claude Code's own Bash sandbox, because it blocks the XPC connection. Run them outside of it.

Validate everything the user asked for, in the sandbox, as the `developer` user:

- `mise run build`, `mise run create`
- Tool versions match the host
- `git status` is clean, and writing to `.git` fails
- Dependencies install, and the host's `node_modules` stay untouched
- Typecheck, lint and tests pass
- Every published port answers from the host (`curl http://127.0.0.1:<port>`)
- `playwright-cli` can open the app, and E2E tests pass if the project has them
- `mise run stop` and `mise run start` work, with services running
- `mise run recreate` keeps the volumes

If the user is using the sandbox, ask before you run `recreate` or `destroy`, because they end all attached sessions.

Finish with a full rebuild from scratch (`destroy`, `build`, `create`, then the checks) so you know the setup works from code alone.

### 5. Report and capture what you learned

Tell the user what works, what you couldn't test, and what they need to do themselves, like logging in to Claude with `mise run claude`.

Then feed learnings back into the boilerplate and this skill, so the next sandbox starts better:

- Something new about Apple container, mise or a tool: add it to the matching reference.
- A new kind of project need (a language, a service, a tool): write a new reference in the same shape as the existing ones, and add it to the table above.
- A fix that every project needs: change the boilerplate, and test it on a lightweight Node project.

List these changes in your report, so the user can review and commit them.
