#!/usr/bin/env bash
# Install command-line productivity tools

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install fzf
if [ ! -d "${HOME}/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.fzf"
    export FZF_ALT_C_COMMAND=""
    "${HOME}/.fzf/install" --key-bindings --no-completion --no-update-rc --no-zsh --no-fish
fi

# Install ripgrep, fd, and screen via apk
sudo apk update
sudo apk add --no-cache ripgrep fd screen py3-pip pipx wireguard-tools
