#!/usr/bin/env bash
# Install Hasklig fonts

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

REAL_HOME=$(get_real_home)
DOTFILES_DIR="${REAL_HOME}/dotfiles"

# Create font directories
run_as_user mkdir -p "${REAL_HOME}/.local/share/fonts"
run_as_user mkdir -p "${REAL_HOME}/.fonts"

# Extract Hasklig fonts to both locations
cd "${DOTFILES_DIR}/qol"
run_as_user unzip -o hasklig.zip -d "${REAL_HOME}/.local/share/fonts/"
run_as_user unzip -o hasklig.zip -d "${REAL_HOME}/.fonts/"

# Refresh font cache for both directories
run_as_user fc-cache -fv "${REAL_HOME}/.local/share/fonts/"
run_as_user fc-cache -fv "${REAL_HOME}/.fonts/"