#!/usr/bin/env bash
# Update all packages

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y