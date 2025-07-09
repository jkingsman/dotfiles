#!/usr/bin/env bash
# Install command-line productivity tools

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

REAL_HOME=$(get_real_home)

# Install fzf
run_as_user git clone --depth 1 https://github.com/junegunn/fzf.git "${REAL_HOME}/.fzf"
run_as_user "${REAL_HOME}/.fzf/install" --key-bindings --no-completion --no-update-rc --no-zsh --no-fish

# Install ripgrep, fd-find, and screen via apt
run_sudo apt update
run_sudo apt install -y ripgrep fd-find screen pipx
