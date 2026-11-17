FROM ubuntu:24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV LANG=C.UTF-8

RUN <<EOF
  set -ex
  apt-get update
  apt-get install -y extrepo
  extrepo enable mise
  apt-get remove -y --auto-remove extrepo
  apt-get update
  apt-get install -y ca-certificates curl git gnupg2 less libatomic1 procps iproute2 mise neovim socat
  rm -fr /var/lib/apt/lists/*
EOF

RUN userdel -r ubuntu && useradd -mu 1000 -s /bin/bash developer

RUN echo 'eval "$(mise activate bash)"' >> /etc/bash.bashrc
ENV PATH="/home/developer/.local/bin:/home/developer/.local/share/mise/shims:$PATH"

# FIXME: remove if you don't need Docker inside your sandboxes
RUN <<EOF
  set -ex
  apt-get update
  apt-get install -y docker.io docker-compose-v2 docker-buildx
  rm -rf /var/lib/apt/lists/*

  usermod -aG docker developer
EOF

# FIXME: remove if you don't need Playwright in your sandboxes, or limit to Chromium
RUN <<EOF
  set -ex
  mise exec node@lts -- npx -y playwright@latest install-deps
  rm -rf /var/lib/apt/lists/* /root/.local /root/.cache /root/.npm
EOF

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
