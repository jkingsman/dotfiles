#!/usr/bin/env bash
# Update all packages

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

run_sudo apt update
run_sudo apt upgrade -y
run_sudo apt autoremove -y