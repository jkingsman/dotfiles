#!/usr/bin/env bash
# Install Python 3.12 via pyenv

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PYTHON_VERSION="3.12.0"

# Install pyenv dependencies
sudo apt update
sudo apt install -y make build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
  libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# Install pyenv
if ! command -v pyenv >/dev/null; then
  curl https://pyenv.run | bash
fi

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