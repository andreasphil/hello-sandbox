# More than one node_modules folder

Applies to workspaces, monorepos, and projects with separate apps or docs sites that each have their own `node_modules`.

## Why each one needs a volume

The host installs packages with macOS binaries: esbuild, rolldown, oxlint, tailwind's oxide, and others. The sandbox needs Linux binaries. If the sandbox shares a `node_modules` folder with the host, one side breaks the other's install. Every `node_modules` folder gets its own volume in the sandbox, and the host's folders stay as they are.

## What to do

1. Find every `node_modules` folder the project uses: `find . -name node_modules -prune -not -path '*/node_modules/*'`, plus the workspace config (`pnpm-workspace.yaml`, `workspaces` in `package.json`).
2. Add a volume per folder to `SANDBOX_VOLUMES` in `mise.toml`, for example:

   ```toml
   SANDBOX_VOLUMES = "node-modules:{{config_root | dirname}}/node_modules frontend-node-modules:{{config_root | dirname}}/frontend/node_modules playwright:/home/developer/.cache/ms-playwright"
   ```

3. The entrypoint hands every volume to the developer, so nothing else is needed.
4. Tell the agent in `CLAUDE.sandbox.md` to run `pnpm install` in each package folder.

With pnpm workspaces, packages often have their own `node_modules` with symlinks into the root's `node_modules/.pnpm`. Those need volumes too, or the host and the sandbox write to the same folders.

## Alternative: install both platforms

pnpm can install binaries for several platforms at once with `supportedArchitectures` (`os: [darwin, linux]`, `cpu: [arm64]`) in `pnpm-workspace.yaml`. Then the host and the sandbox can share `node_modules`. This changes a file the whole team sees, so only do it if the user agrees. The user has preferred volumes so far.
