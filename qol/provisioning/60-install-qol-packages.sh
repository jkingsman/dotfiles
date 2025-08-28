#!/usr/bin/env bash
# Install quality-of-life packages

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install UV (Python package installer)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Poetry (Python dependency management)
curl -sSL https://install.python-poetry.org | python3 -

# Install NVM (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Setup NVM and install Node.js v22
export NVM_DIR="${HOME}/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

bash -c "source $NVM_DIR/nvm.sh && nvm install 22 && nvm use 22 && nvm alias default 22"

# Install Yarn
bash -c "source $NVM_DIR/nvm.sh && npm install -g yarn"

# Install Java (OpenJDK)
sudo apk update
sudo apk add --no-cache openjdk21

# Install Docker
sudo apk add --no-cache docker docker-cli docker-compose-plugin containerd

# Enable Docker service
sudo rc-update add docker boot
sudo service docker start

# Add current user to docker group
sudo usermod -aG docker "$USER"