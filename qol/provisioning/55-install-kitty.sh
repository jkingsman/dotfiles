#!/usr/bin/env bash
# Install and configure kitty terminal

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

REAL_HOME=$(get_real_home)
DOTFILES_DIR="${REAL_HOME}/dotfiles"

# Install kitty
run_sudo apt-get update
run_sudo apt-get install -y kitty

# Create kitty config directories
run_as_user mkdir -p "${REAL_HOME}/.config/kitty/themes"

# Copy theme file
run_as_user cp "${DOTFILES_DIR}/qol/terminal_editor_themes/AtomOneDarkCustomized/kitty.AtomOneDarkCustomized.conf" \
  "${REAL_HOME}/.config/kitty/themes/"

# Create/update kitty config with theme inclusion
echo "include themes/kitty.AtomOneDarkCustomized.conf" | run_as_user tee -a "${REAL_HOME}/.config/kitty/kitty.conf" >/dev/null

# Configure Hasklig font
run_as_user bash -c "cat >> '${REAL_HOME}/.config/kitty/kitty.conf' << EOF
font_family      Hasklig Light
bold_font        Hasklig Medium
italic_font      Hasklig Light Italic
bold_italic_font Hasklig Medium Italic
EOF"