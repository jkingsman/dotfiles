#!/usr/bin/env bash
# Install and configure kitty terminal

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

DOTFILES_DIR="${HOME}/dotfiles"

# Install kitty
run_sudo apt-get update
run_sudo apt-get install -y kitty

# Create kitty config directories
mkdir -p "${HOME}/.config/kitty/themes"

# Copy theme file
cp "${DOTFILES_DIR}/qol/terminal_editor_themes/AtomOneDarkCustomized/kitty.AtomOneDarkCustomized.conf" \
  "${HOME}/.config/kitty/themes/"

# Configure Hasklig font
bash -c "cat >> '${HOME}/.config/kitty/kitty.conf' << EOF
include themes/kitty.AtomOneDarkCustomized.conf

font_family      Hasklig Light
bold_font        Hasklig Medium
italic_font      Hasklig Light Italic
bold_italic_font Hasklig Medium Italic

font_size 13.0
EOF"

