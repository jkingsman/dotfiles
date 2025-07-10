#!/usr/bin/env bash
# Clone dotfiles and run unpack

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

REAL_HOME=$(get_real_home)
DOTFILES_DIR="${REAL_HOME}/dotfiles"

if [ -d "$DOTFILES_DIR" ]; then
  echo "Dotfiles directory already exists: $DOTFILES_DIR"
else
  run_as_user git clone https://github.com/jkingsman/dotfiles.git "$DOTFILES_DIR"
fi

run_as_user chmod -R +x "$DOTFILES_DIR"
(cd "$DOTFILES_DIR" && run_as_user ./.unpack)
