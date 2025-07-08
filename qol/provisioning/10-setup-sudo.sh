#!/usr/bin/env bash
# Setup sudo without password for current user

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

REAL_USER=$(get_real_user)

# If running as root, try to find jack or jkingsman user
if is_root && [ "$REAL_USER" = "root" ]; then
  if id -u jack >/dev/null 2>&1; then
    REAL_USER="jack"
    echo "Running as root, setting up passwordless sudo for user: jack"
  elif id -u jkingsman >/dev/null 2>&1; then
    REAL_USER="jkingsman"
    echo "Running as root, setting up passwordless sudo for user: jkingsman"
  else
    echo "Running as root, but neither jack nor jkingsman user exists. Skipping sudo setup."
    exit 0
  fi
fi

SUDOERS_FILE="/etc/sudoers.d/${REAL_USER}"
echo "${REAL_USER} ALL=(ALL) NOPASSWD:ALL" | run_sudo tee "$SUDOERS_FILE" >/dev/null
run_sudo chmod 0440 "$SUDOERS_FILE"