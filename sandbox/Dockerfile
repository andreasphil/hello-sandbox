FROM ubuntu:24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV LANG=C.UTF-8

# system-level dependencies
#
# - ca-certificates, curl, gnupg2 for loading and verifying tools via mise
# - git to inspect history. .git is read-only, so no commits
# - libatomic1 is required by node
# - jq, less, procps, iproute2, vim for looking around
RUN apt-get update \
  && apt-get -y --no-install-recommends install \
  ca-certificates \
  curl \
  git \
  gnupg2 \
  iproute2 \
  jq \
  less \
  libatomic1 \
  procps \
  vim \
  && rm -rf /var/lib/apt/lists/*

# replace the default ubuntu user, uid 1000, with our developer account
RUN userdel -r ubuntu \
  && useradd -m -u 1000 -s /bin/bash developer

USER developer
WORKDIR /home/developer

# the layers below go from rarely to often changing, so a config edit doesn't
# re-download everything before it

# claude code. CLAUDE_CONFIG_DIR points to a folder on the host shared by all
# sandboxes, so you log in once and the login survives recreating the container.
ENV PATH="/home/developer/.local/bin:/home/developer/.local/share/mise/shims:$PATH"
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV CLAUDE_CONFIG_DIR="/home/developer/.claude"

# files in bind mounts look root-owned, and git refuses to work with them
# unless we mark them safe. `mise run create` copies the global gitignore in.
RUN git config --global safe.directory '*' \
  && git config --global core.excludesFile /home/developer/.gitignore_global

# pnpm would otherwise put its store next to the project, which is on the host
ENV PNPM_CONFIG_STORE_DIR="/home/developer/.local/share/pnpm/store"

# browsers live in a volume, so any playwright version can install its own
# without root, and they survive recreating the container
ENV PLAYWRIGHT_BROWSERS_PATH="/home/developer/.cache/ms-playwright"

# mise for runtimes and tools. shims on PATH make them available in
# non-interactive `container exec` calls, too.
RUN curl -fsSL https://mise.run | sh
COPY --chown=developer:developer mise.sandbox.toml /home/developer/.config/mise/config.toml
RUN mise install

# system libraries for chromium need root. root runs the developer's tools
# through mise, with a throwaway pnpm store so no root-owned files end up in
# the developer's home.
USER root
RUN MISE_CONFIG_DIR=/home/developer/.config/mise \
  MISE_DATA_DIR=/home/developer/.local/share/mise \
  PNPM_CONFIG_STORE_DIR=/tmp/pnpm-store \
  mise exec -- pnpx playwright install-deps chromium \
  && rm -rf /var/lib/apt/lists/* /tmp/pnpm-store /root/.cache /root/.local

# agent instructions for the sandbox. claude loads them on top of the
# project's CLAUDE.md
COPY CLAUDE.sandbox.md /etc/claude-code/CLAUDE.md
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
