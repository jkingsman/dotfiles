#!/usr/bin/env bash
# Install i3 window manager configuration

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

REAL_HOME=$(get_real_home)
DOTFILES_DIR="${REAL_HOME}/dotfiles"

# Create i3 config directory
run_as_user mkdir -p "${REAL_HOME}/.config/i3"

# Copy i3 config file
run_as_user cp "${DOTFILES_DIR}/i3.config" "${REAL_HOME}/.config/i3/config"