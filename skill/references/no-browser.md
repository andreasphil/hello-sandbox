# No browser

Applies when the project never needs a browser: CLIs, libraries, backends without a UI. If the user agrees, remove Playwright from the boilerplate, so the image is smaller and builds faster.

## What to remove

- `Dockerfile`:
  - the `PLAYWRIGHT_BROWSERS_PATH` variable
  - the `playwright-cli install --skills` step
  - the root step with `playwright install-deps`
  - the step that moves the skills into `/etc/claude-code/.claude/skills`
- `mise.sandbox.toml`: the `npm:@playwright/cli` tool and the `PLAYWRIGHT_*` variables
- `mise.toml`: the `playwright` volume in `SANDBOX_VOLUMES`
- `CLAUDE.sandbox.md`: the Playwright bullet
- `README.md`: the browser rows in the access and persistence tables

## Keep in mind

- The entrypoint must run as root, because it hands volumes to the developer. In the boilerplate, the `install-deps` step switches to root. Without that step, add `USER root` before `ENTRYPOINT`, or the entrypoint's `chown` fails.
- Keep `/etc/claude-code/CLAUDE.md`. Claude finds managed instructions there, whether or not the skills folder exists.
- If the project has no servers either, set `SANDBOX_PORTS` to `""`. The `create` task handles an empty list. Also remove the bullets about dev servers from `CLAUDE.sandbox.md`.
