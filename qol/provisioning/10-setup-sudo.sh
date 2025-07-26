#!/usr/bin/env bash
# Setup sudo without password for current user

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SUDOERS_FILE="/etc/sudoers.d/${USER}"
echo "${USER} ALL=(ALL) NOPASSWD:ALL" | sudo tee "$SUDOERS_FILE" >/dev/null
sudo chmod 0440 "$SUDOERS_FILE"