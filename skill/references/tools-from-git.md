# Tools from git

Applies when the user wants a tool in the sandbox that isn't released as a package, like their own CLI, so the image builds it from its repository.

## Pin the commit in the build task

A plain `git clone` of a branch in the Dockerfile is cached forever. The layer only rebuilds with `--no-cache`, which downloads everything else in the image again too. Instead, look up the branch's latest commit on the host in the `build` task, and pass it as a build argument:

```toml
[tasks.build]
run = """
  container build \\
    --tag "$SANDBOX_NAME" \\
    --build-arg "TOOL_COMMIT=$(git ls-remote https://github.com/<owner>/<tool>.git refs/heads/main | cut -f1)" \\
    .
"""
```

```dockerfile
ARG TOOL_COMMIT
RUN test -n "$TOOL_COMMIT" \
  && git clone https://github.com/<owner>/<tool>.git /home/developer/.local/share/<tool> \
  && cd /home/developer/.local/share/<tool> \
  && git checkout --quiet "$TOOL_COMMIT" \
  && pnpm install --frozen-lockfile \
  && pnpm build \
  && ln -s /home/developer/.local/share/<tool>/bin/<tool>.mjs /home/developer/.local/bin/<tool>
```

- The layer rebuilds exactly when the branch has a new commit. Otherwise `build` uses the cache.
- `test -n` fails the build early if the lookup failed, for example without network.
- Check out the commit, not the branch. The branch may move between the lookup and the clone.
- Put the layer after the runtimes it needs, like Node and pnpm, and after the other version build arguments. A new commit then rebuilds only this layer and the ones after it.
- Install as the developer, into the developer's home, and link the binary into `~/.local/bin`, which is on `PATH`.
- Private repositories need credentials at build time. Don't put them in the image. Ask the user, and see `secrets-1password.md`.

## Skills that come with a tool

If the tool ships a Claude skill, install it in the image, into `/etc/claude-code/.claude/skills`. That's Claude's managed skills folder, so the skill loads in every project. Don't use `~/.claude/skills`: the shared Claude folder is mounted over `~/.claude` and hides it. Don't use the project's `.claude/skills` either, it changes the project for everyone.

Tools often write their skill to `.claude/skills` in the current folder. Run them in a temporary folder as the developer, then move the result as root:

```dockerfile
RUN mkdir /tmp/skills && cd /tmp/skills \
  && <tool> skill install
USER root
RUN mkdir -p /etc/claude-code/.claude \
  && mv /tmp/skills/.claude/skills /etc/claude-code/.claude/skills \
  && rm -rf /tmp/skills
```

The boilerplate already does this for `playwright-cli`. Add further tools to the same temporary folder instead of a second move.

## Tell the user

- In the sandbox's README: `build` + `recreate` picks up new commits. No `--no-cache` needed.
- If the repo is the user's own and they also use the tool on the host, mention that the sandbox follows the branch, not the version installed on the host.
