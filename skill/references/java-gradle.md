# Java and Gradle

Applies when the project has a JVM backend or tools built with Gradle or Maven.

## Installing Java

Install Java through mise in its own early Dockerfile layer, so version bumps elsewhere don't download the JDK again:

```dockerfile
RUN mise use --global java@25
ENV JAVA_HOME="/home/developer/.local/share/mise/installs/java/25"
```

- Take the version from the build's toolchain setting, for example `JavaLanguageVersion.of(25)` in `build.gradle.kts`. Project docs may be out of date.
- Set `JAVA_HOME` explicitly. Shims put `java` on `PATH`, but some tools only look at `JAVA_HOME`. mise links the major version (`installs/java/25`) to the installed release.
- Set `LANG=C.UTF-8` in the image. Without a UTF-8 locale, Java breaks on non-ASCII file names.

## Gradle cache

Give the Gradle cache its own volume, so dependencies survive `recreate`:

```toml
SANDBOX_VOLUMES = "... gradle:/home/developer/.gradle"
```

The sandbox then has its own cache, separate from the host's `~/.gradle`. That matters because the host's `gradle.properties` often contains credentials.

## Things to know

- The project's `build/` folders are shared with the host. Gradle's outputs are portable, so this works, but running Gradle on both sides at the same time can clash. Up-to-date checks also carry over: a test task the host already ran may be skipped in the sandbox. Use `--rerun-tasks` when you need a real run.
- Private dependencies, like GitHub Packages, need credentials. See `secrets-1password.md`.
- Spring Boot listens on all interfaces by default, so a published port works without changes.
- Integration tests with Testcontainers need Docker. See `docker.md`.
- Tell the agent in `CLAUDE.sandbox.md` how to run the backend, with the right profile, for example `./gradlew bootRun --args='--spring.profiles.active=default,e2e'`.
- Resources: a JVM backend plus a frontend, tests and maybe OpenSearch need more than the boilerplate's defaults. 8 CPUs and 12 GB worked for one such project.
