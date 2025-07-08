#!/usr/bin/env bash
# Common utility functions for provisioning scripts

set -e

# Check if running as root
is_root() {
  [ "$(id -u)" -eq 0 ]
}

# Run command with sudo if not root
run_sudo() {
  if is_root; then
    "$@"
  else
    sudo "$@"
  fi
}

# Get the actual user (not root if using sudo)
get_real_user() {
  if is_root && [ -n "$SUDO_USER" ]; then
    echo "$SUDO_USER"
  else
    echo "$USER"
  fi
}

# Get the actual home directory
get_real_home() {
  local real_user=$(get_real_user)
  if [ -n "$real_user" ]; then
    echo "$(getent passwd "$real_user" | cut -d: -f6)"
  else
    echo "$HOME"
  fi
}

# Run command as the real user (not root)
run_as_user() {
  local real_user=$(get_real_user)
  if is_root && [ -n "$real_user" ]; then
    sudo -u "$real_user" "$@"
  else
    "$@"
  fi
}

export -f is_root run_sudo get_real_user get_real_home run_as_user