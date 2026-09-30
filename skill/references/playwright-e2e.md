# Playwright E2E tests

Applies when the project has Playwright tests, or when the agent needs a browser to explore the app.

## What the boilerplate does

- The build installs Chromium's system libraries as root with `playwright install-deps chromium`. They rarely change between Playwright versions.
- Browsers aren't in the image. `PLAYWRIGHT_BROWSERS_PATH` points to a volume, so any Playwright version can install its own browser without root, and it survives `recreate`.
- `PLAYWRIGHT_HTML_OPEN=never` keeps the HTML reporter from trying to open a browser after a test run.
- `playwright-cli` is installed for exploring the app. `PLAYWRIGHT_MCP_BROWSER=chromium` makes it use Chromium. Its default is Google Chrome, which doesn't exist for Linux on ARM. Install its browser once with `playwright-cli install-browser chromium`.

## E2E tests

- Install the browser that matches the project's Playwright version: `pnpm exec playwright install chromium`. Put this in `CLAUDE.sandbox.md`.
- E2E tests usually need running servers. Check `playwright.config.ts` for `webServer`. If it's missing, the agent has to start the servers first. Write the commands and their order into `CLAUDE.sandbox.md`.
- Default to the Chromium project unless the tests are about browser differences. Firefox and WebKit need their own system libraries: add them to the `install-deps` line in the Dockerfile.
- Tests that depend on environment variables, like feature flags, need them in the `[env]` of `mise.sandbox.toml` if the project doesn't set them itself.

## Preinstalling the browser in the image

If the user wants E2E tests to work without an install step, install the browser at build time. It has to be the project's Playwright version:

```dockerfile
ARG PLAYWRIGHT_VERSION
RUN test -n "$PLAYWRIGHT_VERSION" \
  && pnpx "playwright@$PLAYWRIGHT_VERSION" install chromium
```

Read the version from `package.json` in the `build` task (see `versions-from-package-json.md`). Then `PLAYWRIGHT_BROWSERS_PATH` must point to a folder in the image, not to a volume, because the volume would hide what the image installed. Remove the `playwright` entry from `SANDBOX_VOLUMES`.

## Checking that it works

```sh
node -e 'import("@playwright/test").then(async ({ chromium }) => {
  const b = await chromium.launch(); console.log(b.version()); await b.close();
})'
```

Run it in the project folder, where `@playwright/test` is installed.
