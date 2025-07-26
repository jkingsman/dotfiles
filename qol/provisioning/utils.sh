#!/usr/bin/env bash
# Common utility functions for provisioning scripts

set -e

# Run command with sudo
run_sudo() {
  sudo "$@"
}

export -f run_sudo