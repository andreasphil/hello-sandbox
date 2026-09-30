# Versions from package.json

Applies when the project defines tool versions in `package.json` instead of mise: `devEngines`, `engines`, `packageManager`, or a pinned `@playwright/test`.

## Why

If the sandbox pins its own versions in `mise.sandbox.toml`, they drift from the project's. Reading them from `package.json` at build time keeps them in sync without anyone having to remember.

Some projects fail or warn when versions don't match exactly. For example `devEngines.runtime` with `"onFail": "warn"` prints warnings on every pnpm command if Node is off by a patch version.

## What to do

1. Remove `node` and `pnpm` from the `[tools]` in `mise.sandbox.toml`.
2. Pass the versions as build arguments in the `build` task. Quote the path, and use `jq` so the values come out raw:

   ```toml
   [tasks.build]
   run = """
     package_json="$SANDBOX_REPO/package.json"
     container build \\
       --tag "$SANDBOX_NAME" \\
       --build-arg "NODE_VERSION=$(jq -r .devEngines.runtime.version "$package_json")" \\
       --build-arg "PNPM_VERSION=$(jq -r .devEngines.packageManager.version "$package_json")" \\
       .
   """
   ```

3. Install them in the Dockerfile, and fail early if an argument is empty:

   ```dockerfile
   ARG NODE_VERSION
   ARG PNPM_VERSION
   RUN test -n "$NODE_VERSION" && test -n "$PNPM_VERSION" \
     && mise use --global "node@$NODE_VERSION" "pnpm@$PNPM_VERSION"
   ```

4. Keep the build arguments late in the Dockerfile. Every layer after an `ARG` that changes gets rebuilt, so version bumps shouldn't sit in front of large downloads like Claude Code or other runtimes.

## Where versions live

| Field                               | Example                                                       |
| ----------------------------------- | ------------------------------------------------------------- |
| `devEngines.runtime.version`        | `{ "name": "node", "version": "26.6.0" }`                     |
| `devEngines.packageManager.version` | `{ "name": "pnpm", "version": "11.20.0" }`                    |
| `packageManager`                    | `"pnpm@11.20.0+sha512..."`, strip everything from `+`         |
| `engines.node`                      | often a range like `>=22`, not an exact version: ask the user |

Check which `package.json` is the source of truth in monorepos. It may not be the root one.

For Playwright versions, see `playwright-e2e.md`.
