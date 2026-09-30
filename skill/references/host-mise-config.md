# Host-specific mise config in the project

Applies when the project's mise files, often a gitignored `mise.local.toml`, contain settings that only make sense on the host.

## Why it matters

The boilerplate trusts the project's mise config inside the sandbox, so its tools, environment and tasks work there too. Settings that point at the host then break in the sandbox. Examples found so far:

- `DOCKER_HOST` pointing at a socket on the host, like colima's. It overrides the sandbox's own Docker.
- Tools that only make sense on the host, like CLIs for Jira or vulnerability scanners. mise tries to install them on `mise install`.
- Tasks that call `op` (1Password) or other host tools.
- Absolute paths into the user's home directory.

## What to do

Look at every mise file in the project, including gitignored ones, and decide per file:

- **Harmless:** leave it. The project's tasks and environment are useful in the sandbox.
- **Host-specific:** ignore it in the sandbox. Add it to `MISE_IGNORED_CONFIG_PATHS` on `container run` in the `create` task:

  ```sh
  --env "MISE_IGNORED_CONFIG_PATHS=$SANDBOX_REPO/mise.local.toml" \
  ```

  Several paths are separated by `:`. This has to be an environment variable, because mise doesn't render templates in `[settings]`.

  Then copy what the sandbox still needs from the ignored file, like tool versions or environment variables, into `mise.sandbox.toml`. Note in a comment that it's a copy, so the two can be kept in sync.

- **Mixed:** if only one setting is host-specific and the user agrees, moving that setting out of the project is cleaner than ignoring the whole file. For example, `DOCKER_HOST` can move to the user's global mise config or become a Docker context.

Also check the tool versions. If the project pins versions the sandbox should match, use those in `mise.sandbox.toml`. If the project's file is trusted in the sandbox, its versions win inside the project folder anyway.
