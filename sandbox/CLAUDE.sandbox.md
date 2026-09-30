# Sandbox

You are running inside a sandbox container. See `sandbox/README.md` in the project for how it's set up. This changes some of the project instructions:

- Nothing is running when you start. Start dev servers and other services yourself when you need them, in the background. If the project instructions say to ask the user to start them, ignore that here.
- Dev servers must listen on all interfaces, or the user can't reach them from the host. For Vite that's `pnpm dev --host`. The user opens them at `http://localhost:<port>`. `SANDBOX_PORTS` in `sandbox/mise.toml` lists the published ports.
- `.git` is read-only. You can inspect history, diffs and branches, but you can't commit, switch branches, or stash. Leave committing to the user.
- Don't push, pull, or fetch. The sandbox has no Git credentials, so these fail.
- `node_modules` is a volume, separate from the host. Run `pnpm install` if it's missing or outdated. This doesn't affect the host.
- Playwright's system libraries are installed, but browsers aren't. They are kept in a volume, so you only install them once:
  - For E2E tests: `pnpm exec playwright install chromium`, which matches the project's Playwright version.
  - For exploring the app with `playwright-cli`: `playwright-cli install-browser chromium`. It uses Chromium by default in here; Google Chrome isn't available for Linux on ARM.
- Files the user edits on the host don't trigger file watchers in here. Your own edits do.
- You can't install system packages (no root). If a tool is missing, tell the user so they can add it to `sandbox/Dockerfile` or `sandbox/mise.sandbox.toml`.
- Don't change files in `sandbox/` unless the user asks. Changes only take effect after the user rebuilds the sandbox on the host.
