#!/usr/bin/env bash
# Install and configure kitty terminal

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DOTFILES_DIR="${HOME}/dotfiles"

# Install kitty
sudo apt-get update
sudo apt-get install -y kitty

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

map ctrl+w close_window
map ctrl+t new_tab
map ctrl+shift+d launch --location=vsplit
EOF"

