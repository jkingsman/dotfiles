#!/usr/bin/env bash
# Install i3 window manager and configuration

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

REAL_HOME=$(get_real_home)
DOTFILES_DIR="${REAL_HOME}/dotfiles"

# Install i3 and related packages
run_sudo apt update
# i3 basics
run_sudo apt install -y i3-wm i3status i3lock
run_sudo apt isntall -y dunst # notifications
run_sudo apt install -y xdotool # numlock light
run_sudo apt install -y rofi # menu/launcher
run_sudo apt install -y pasystray # tray audio
run_sudo apt install -y feh # wallpaper etc.

# Create i3 config directory
run_as_user mkdir -p "${REAL_HOME}/.config/i3"

# Copy i3 config file
run_as_user cp "${DOTFILES_DIR}/qol/provisioning/i3.config" "${REAL_HOME}/.config/i3/config"
