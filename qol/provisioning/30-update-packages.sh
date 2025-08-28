#!/usr/bin/env bash
# Update all packages

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo apk update
sudo apk upgrade
# Alpine doesn't have autoremove, packages are minimal by default