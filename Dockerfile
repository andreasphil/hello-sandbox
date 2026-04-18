FROM ubuntu:latest

# install system-level dependencies
#
# - ca-certificates, curl, gnupg2 for being able to load and verify dependencies via mise
# - git to inspect commits (push/pull should not work unless you provide credentials)
# - libatomic1 is required by node
# - vim to edit files if needed
# 
RUN apt-get update \
  && apt-get -y --no-install-recommends install \
  ca-certificates \
  curl \
  git \
  gnupg2 \
  libatomic1 \
  vim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# set locale (otherwise java will break when encountering non-ascii filenames)
ENV LANG=C.utf-8
ENV LC_ALL=C.utf-8

# setup pnpm + node - this needs to happen globally because we need sudo for
# installing playwright browsers with system dependencies.
ENV PNPM_HOME="/usr/local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN curl -fsSL https://get.pnpm.io/install.sh | SHELL="$(which bash)" sh
RUN pnpm env use --global lts

# setup playwright browsers for e2e testing. browser installations are shared
# between users so our developer account can run e2e tests without having to
# install browsers by itself (which would require root privileges)
ENV PLAYWRIGHT_BROWSERS_PATH="/usr/local/share/playwright"
RUN pnpx playwright install chromium --with-deps

# set up user with reduced permissions
RUN useradd -ms /bin/bash developer
RUN chmod -R a+rX $PNPM_HOME
RUN chmod -R a+rX $PLAYWRIGHT_BROWSERS_PATH

USER developer
WORKDIR /home/developer

# setup mise for other dependencies. ".local/bin" is the default installation
# path for mise so it needs to be added to the path.
ENV PATH=".local/bin:$PATH"
RUN curl https://mise.run/bash | sh
RUN mise use -g claude java@21
