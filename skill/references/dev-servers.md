# Dev servers and ports

Applies when the user opens dev servers or services from the host: frontends, APIs, Storybook, dashboards.

## Listen on all interfaces

Published ports forward to the container's network interface, not to its loopback. A server that only listens on `localhost` inside the container can't be reached from the host. Each server needs to listen on `0.0.0.0`:

| Server          | How                                                               |
| --------------- | ----------------------------------------------------------------- |
| Vite            | `vite --host`, or `pnpm dev --host`                               |
| Nuxt            | `NUXT_HOST=0.0.0.0` in the `[env]` of `mise.sandbox.toml`         |
| Storybook       | listens on all interfaces by default                              |
| Spring Boot     | listens on all interfaces by default                              |
| Docker services | published ports inside the sandbox listen on `0.0.0.0` by default |

Prefer an environment variable in `mise.sandbox.toml` over a flag, because it works no matter how the agent starts the server. Where only a flag exists, tell the agent in `CLAUDE.sandbox.md`.

Test it from the host with `curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:<port>/`.

A generic alternative, if many servers need it: forward the container's interface to loopback in the entrypoint with `iptables` DNAT and `route_localnet`. It needs `--cap-add NET_ADMIN` and a writable `/proc/sys`. It's harder to understand, so only use it if flags and variables don't cover the project.

## Publishing ports

- List every port in `SANDBOX_PORTS` in `mise.toml`. `create` publishes them to `127.0.0.1` on the host. Changes need `recreate`.
- Ports clash with the same ports used on the host. Tell the user to stop the host's servers first.
- If the frontend calls a backend by URL, `http://localhost:<port>` works both in the browser on the host and for server-side rendering in the sandbox, because both use the same port numbers.

## Starting servers

- The agent starts servers itself, in the background. Put the exact commands in `CLAUDE.sandbox.md`, especially when they differ from the host, like extra flags or profiles.
- If the project's `CLAUDE.md` tells the agent to ask the user to start servers, override that in `CLAUDE.sandbox.md`.

## Hot reload

File changes made on the host don't trigger file watchers in the sandbox. Hot reload works for the agent's edits. If the user wants hot reload for their own edits on the host too, the dev server has to poll, for example Vite's `server.watch.usePolling`. Polling costs CPU all the time, so ask before you turn it on.
