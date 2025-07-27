#!/usr/bin/env bash
# Install command-line productivity tools

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install fzf
if [ ! -d "${HOME}/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.fzf"
    "${HOME}/.fzf/install" --key-bindings --no-completion --no-update-rc --no-zsh --no-fish
fi

# Install ripgrep, fd-find, and screen via apt
sudo apt update
sudo apt install -y ripgrep fd-find screen pipx
