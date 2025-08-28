#!/usr/bin/env bash
# Install and configure kitty terminal

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DOTFILES_DIR="${HOME}/dotfiles"

# Install kitty
sudo apk update
sudo apk add --no-cache kitty

# Create kitty config directories
mkdir -p "${HOME}/.config/kitty/themes"

# Copy theme file
cp "${DOTFILES_DIR}/qol/terminal_editor_themes/AtomOneDarkCustomized/kitty.AtomOneDarkCustomized.conf" \
  "${HOME}/.config/kitty/themes/"

# Configure Hasklig font
cp "${DOTFILES_DIR}/qol/provisioning/kitty.conf" "${HOME}/.config/kitty/kitty.conf"

