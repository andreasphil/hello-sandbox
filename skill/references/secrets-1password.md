# Secrets and 1Password

Applies when installing, building or testing needs credentials: private package registries, API tokens, basic auth for staging.

## Rules

- Secrets live in 1Password, never in files in the project or the sandbox. Don't suggest `.env` files or putting tokens in config.
- Ask the user for the 1Password reference (`op://vault/item/field`), never for the secret itself. Check the item's field names with `op item get "<item>" --vault <vault> --format json | jq -r '.fields[] | .label'`, which doesn't print values.
- The sandbox never stores a secret. The agent inside can read anything the sandbox keeps, including environment variables and files in volumes.

## Pattern: give the secret to one command

Read the secret on the host and pass it to a single `container exec`. `--env NAME` without a value takes the variable from the calling shell, so the secret doesn't show up in the process list:

```toml
[env]
SANDBOX_GH_PACKAGES_TOKEN_REF = "op://<vault>/<item>/<field>"

[tasks.deps]
description = "Download private dependencies into the Gradle volume"
run = """
  GH_PACKAGES_REPOSITORY_USER=sandbox
  GH_PACKAGES_REPOSITORY_TOKEN=$(op read "$SANDBOX_GH_PACKAGES_TOKEN_REF")
  export GH_PACKAGES_REPOSITORY_USER GH_PACKAGES_REPOSITORY_TOKEN

  container exec --user developer \\
    --workdir "$SANDBOX_REPO" \\
    --env GH_PACKAGES_REPOSITORY_USER \\
    --env GH_PACKAGES_REPOSITORY_TOKEN \\
    "$SANDBOX_NAME" ./gradlew --console=plain compileJava
"""
```

This works for anything that downloads once into a cache that lives in a volume: Gradle and Maven dependencies, pnpm packages from a private registry. Afterwards, builds work from the cache without the secret. Tell the user to run the task again when the private dependencies change.

Check it: after the task, run the build again in a normal session without the variables. If it still resolves, the cache is enough.

## When the secret is needed every time

If a command needs the secret on every run, like smoke tests against staging, don't put it in the sandbox. Options, in order of preference:

1. Run that command on the host.
2. A host task that reads the secret and runs the command through `container exec --env`, as above.
3. If the user accepts the risk: pass it with `--env` on `container run`. The agent can then read it, and it shows up in `container inspect`. Only for low-value secrets, and only with the user's explicit agreement.

## GitHub Packages

- Maven and Gradle need a username and a token. With a personal access token, any username works, because the token identifies the user. `sandbox` is fine.
- A token that only reads public packages is low-value, but it still depends on being configured correctly. Treat it like a secret.
- The username and token variable names come from the project's build file, for example `GH_PACKAGES_REPOSITORY_USER` and `GH_PACKAGES_REPOSITORY_TOKEN` in `build.gradle.kts`.
