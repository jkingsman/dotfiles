#!/usr/bin/env bash
# Main provisioning script that runs all component scripts

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run all provisioning scripts in order
for script in "$SCRIPT_DIR"/[0-9]*.sh; do
  if [ -f "$script" ] && [ -x "$script" ]; then
    echo "=== Running $(basename "$script") ==="
    "$script"
  fi
done

echo "=== Provisioning complete! ==="
echo "You should log out and back in for all changes to take effect."
echo "NOTE: Docker group membership requires a logout/login to take effect."

exec ${SHELL} -l