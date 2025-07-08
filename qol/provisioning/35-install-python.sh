#!/usr/bin/env bash
# Install Python 3.12 via pyenv

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

PYTHON_VERSION="3.12.0"
REAL_HOME=$(get_real_home)

# Install pyenv dependencies
run_sudo apt update
run_sudo apt install -y make build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
  libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# Install pyenv as the real user
if ! run_as_user command -v pyenv >/dev/null; then
  run_as_user curl https://pyenv.run | run_as_user bash
fi

# Setup pyenv environment
export PYENV_ROOT="${REAL_HOME}/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)" 2>/dev/null || true

# Install Python version if not already installed
if ! pyenv versions | grep -q "$PYTHON_VERSION"; then
  run_as_user pyenv install "$PYTHON_VERSION"
fi

run_as_user pyenv global "$PYTHON_VERSION"