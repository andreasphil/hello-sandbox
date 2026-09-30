# Symlinked config and sandboxes outside the project

Applies when the project contains symlinks to files outside it, like a personal `CLAUDE.md`, `.claude/`, editor config or `mise.local.toml` kept in another repo. Also applies when the sandbox folder itself should live outside the project.

## Symlinks into another folder

Inside the sandbox, a symlink only resolves if its target is mounted too. Mount the target at the same absolute path it has on the host, and the link works unchanged.

1. Find the links: `find . -maxdepth 2 -type l -not -path './node_modules/*' -exec ls -l {} \;`
2. Group them by target folder. Usually they all point into one folder, like `<utils-repo>/<project>/`.
3. Mount that folder read-only in `create`, at the same path:

   ```sh
   --mount "type=bind,source=$SANDBOX_LINKED_DIR,target=$SANDBOX_LINKED_DIR,readonly" \
   ```

4. Mount the whole folder, not the single link targets. Apple container can't mount single files, and one folder mount also covers links the user adds later.
5. List what else is in that folder and ask the user before you mount it. Everything in it becomes readable for the agent.

Read-only matters here: files like `.claude/` settings and hooks, or `lefthook-local.yml`, run on the host later. The agent mustn't be able to change them.

Tell the agent in `CLAUDE.sandbox.md` which files are read-only, so it doesn't try to edit them. A project `CLAUDE.md` that's a symlink won't load at all if the target isn't mounted, and the agent then works without the project instructions. Check this.

## The sandbox folder outside the project

The user may prefer to keep the sandbox in their utils repo and symlink it into the project, like the other personal files. This has one clear benefit: if the target folder is mounted read-only, the agent can't edit its own sandbox configuration.

Things to handle:

- **Paths in `mise.toml`:** `{{config_root}}` resolves symlinks, so it points into the utils repo, not the project. Set `SANDBOX_REPO` to the project's absolute path instead of deriving it from `config_root`. The linked folder can still be derived: `SANDBOX_LINKED_DIR = "{{config_root | dirname}}"`.
- **Container name:** `SANDBOX_NAME` in the boilerplate comes from the parent folder of `config_root`. Check it still gives the project's name, or set it explicitly.
- **Git ignore:** git treats a symlink as a file, so a `sandbox/` pattern with a trailing slash doesn't match it. Use `sandbox`.
- **mise trust:** trust is stored per path. Run `mise trust` again after the move.
- **Relative links in the README** resolve from the real location. Use absolute or web links for files in the project.
- **Rebuild:** after the move, run `build` and `recreate` once to check that everything resolves.
