#!/usr/bin/env bash
# Install Python 3.12 via pyenv

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PYTHON_VERSION="3.12.0"

# Install pyenv dependencies
sudo apk update
sudo apk add --no-cache make build-base openssl-dev zlib-dev \
  bzip2-dev readline-dev sqlite-dev wget curl llvm \
  ncurses-dev xz tk-dev libxml2-dev libxslt-dev libffi-dev xz-dev

# Install pyenv
if ! command -v pyenv >/dev/null && [ ! -d "${HOME}/.pyenv" ]; then
  curl https://pyenv.run | bash

  # Setup pyenv environment
  export PYENV_ROOT="${HOME}/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)" 2>/dev/null || true

  # Install Python version if not already installed
  if ! pyenv versions | grep -q "$PYTHON_VERSION"; then
    pyenv install "$PYTHON_VERSION"
  fi

  pyenv global "$PYTHON_VERSION"
fi
