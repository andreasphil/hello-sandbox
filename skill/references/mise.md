# mise

Quirks of mise found while building sandboxes, on the host and inside the container.

## Templates in tasks

- mise renders task scripts and `[env]` values as Tera templates. `{{ ... }}` is an expression and `{# ... #}` starts a comment. Both break shell code that happens to contain them:
  - Docker and Go format strings like `docker ps --format '{{.Names}}'` fail. Use `--format json` and format with `jq` instead.
  - Bash's `${#array[@]}` contains `{#` and breaks. Use a string you append to, or test with `[[ -z ... ]]`.
- Templates don't work in `[settings]`. For settings that need a path, set the matching `MISE_*` environment variable instead, for example `MISE_IGNORED_CONFIG_PATHS` on `container run`.
- Useful template values: `{{config_root}}` is the folder of the config file. Path filters work: `{{config_root | dirname}}`, `{{config_root | dirname | basename}}`. `{{env.HOME}}` reads the environment.

## Paths and symlinks

- `{{config_root}}` resolves symlinks. If the sandbox folder is a symlink, `config_root` is the real folder, not the one inside the project. `cd ..` in a task depends on where the user started, so don't rely on it either. See `symlinked-config.md`.
- Tasks run in `config_root` by default.

## Trust

- mise refuses to load config files it doesn't trust, and that failure breaks every shim, including `node` and `pnpm`. Inside the container, nothing is trusted at first. The boilerplate sets `MISE_TRUSTED_CONFIG_PATHS` to the project, so the project's mise config applies like on the host.
- Trust is stored per path. After moving a sandbox folder, run `mise trust` in the new location.

## Tools and shims

- The boilerplate puts `~/.local/share/mise/shims` on `PATH`. Shims apply the mise environment and tool versions to non-interactive `container exec` calls, which don't load a shell profile.
- `mise use --global tool@version` both writes the global config and installs the tool. Useful in a Dockerfile.
- Global config can be split: mise also loads `~/.config/mise/conf.d/*.toml`. This helps when a Dockerfile writes tools with `mise use` and copies environment settings separately.
- The project's tool versions win over the global ones inside the project folder. If the project pins a version the image doesn't have, mise installs it on first use.
- mise shims don't work for root, because root has its own config and data folders. To run the developer's tools as root, for example during the build, set `MISE_CONFIG_DIR` and `MISE_DATA_DIR` to the developer's folders and use `mise exec`. The boilerplate does this for `playwright install-deps`.

## pnpm

- pnpm 11 and later read configuration from `PNPM_CONFIG_*` environment variables (any case). `npm_config_*` variables are ignored.
- Without an explicit store location, pnpm may put its store next to the project, on the host. The boilerplate sets `PNPM_CONFIG_STORE_DIR` to a folder in the container.
- `pnpm config set --global` fails if pnpm's global bin folder isn't on `PATH`. Environment variables avoid that.
