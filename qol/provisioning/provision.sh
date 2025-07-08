#!/usr/bin/env bash
# Main provisioning script that runs all component scripts

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run all provisioning scripts in order
"${SCRIPT_DIR}/05-setup-dotfiles.sh"
"${SCRIPT_DIR}/10-setup-sudo.sh"
"${SCRIPT_DIR}/15-install-essentials.sh"
"${SCRIPT_DIR}/20-install-fonts.sh"
"${SCRIPT_DIR}/25-configure-ssh.sh"
"${SCRIPT_DIR}/30-update-packages.sh"
"${SCRIPT_DIR}/35-install-python.sh"
"${SCRIPT_DIR}/40-install-bash.sh"
"${SCRIPT_DIR}/45-install-i3-config.sh"
"${SCRIPT_DIR}/50-install-cli-tools.sh"
"${SCRIPT_DIR}/55-install-kitty.sh"
"${SCRIPT_DIR}/60-install-qol-packages.sh"
"${SCRIPT_DIR}/65-check-apps.sh"

echo "=== Provisioning complete! ==="
echo "You should log out and back in for all changes to take effect."
echo "NOTE: Docker group membership requires a logout/login to take effect."

exec ${SHELL} -l