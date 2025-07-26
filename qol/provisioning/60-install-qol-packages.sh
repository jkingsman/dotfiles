#!/usr/bin/env bash
# Install quality-of-life packages

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

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

# Install Java (OpenJDK 21)
run_sudo apt update
if apt-cache show openjdk-21-jdk &>/dev/null; then
  run_sudo apt install -y openjdk-21-jdk
fi

# Install Docker
run_sudo apt-get install -y ca-certificates curl
run_sudo install -m 0755 -d /etc/apt/keyrings

# Detect OS and set Docker repo variables
. /etc/os-release
if [[ "$ID" == "ubuntu" ]]; then
  DOCKER_GPG_URL="https://download.docker.com/linux/ubuntu/gpg"
  DOCKER_REPO="deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME:-$VERSION_CODENAME} stable"
elif [[ "$ID" == "debian" ]]; then
  DOCKER_GPG_URL="https://download.docker.com/linux/debian/gpg"
  DOCKER_REPO="deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $VERSION_CODENAME stable"
else
  echo "Unsupported OS for Docker install: $ID"
  exit 1
fi

run_sudo curl -fsSL "$DOCKER_GPG_URL" -o /etc/apt/keyrings/docker.asc
run_sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "$DOCKER_REPO" | run_sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

run_sudo apt-get update
run_sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
run_sudo usermod -aG docker "$USER"