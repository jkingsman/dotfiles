#!/usr/bin/env bash
# Clone dotfiles and run unpack

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DOTFILES_DIR="${HOME}/dotfiles"

if [ -d "$DOTFILES_DIR" ]; then
  echo "Dotfiles directory already exists: $DOTFILES_DIR"
else
  git clone https://github.com/jkingsman/dotfiles.git "$DOTFILES_DIR"
fi

chmod -R +x "$DOTFILES_DIR"
(cd "$DOTFILES_DIR" && ./.unpack)
