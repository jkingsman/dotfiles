#!/usr/bin/env bash
# Install fonts

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DOTFILES_DIR="${HOME}/dotfiles"

# Create font directories
mkdir -p "${HOME}/.local/share/fonts"
mkdir -p "${HOME}/.fonts"

# Extract fonts to both locations
cd "${DOTFILES_DIR}/qol"
unzip -o fonts.zip -d "${HOME}/.local/share/fonts/"
unzip -o fonts.zip -d "${HOME}/.fonts/"

# Refresh font cache for both directories
fc-cache -fv "${HOME}/.local/share/fonts/"
fc-cache -fv "${HOME}/.fonts/"
