#!/usr/bin/env bash
# Install quality-of-life packages

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

REAL_HOME=$(get_real_home)

# Install UV (Python package installer)
run_as_user curl -LsSf https://astral.sh/uv/install.sh | run_as_user sh

# Install Poetry (Python dependency management)
run_as_user curl -sSL https://install.python-poetry.org | run_as_user python3 -

# Install NVM (Node Version Manager)
run_as_user curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | run_as_user bash

# Setup NVM and install Node.js v22
export NVM_DIR="${REAL_HOME}/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

run_as_user bash -c "source $NVM_DIR/nvm.sh && nvm install 22 && nvm use 22 && nvm alias default 22"

# Install Yarn
run_as_user bash -c "source $NVM_DIR/nvm.sh && npm install -g yarn"

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

# Add real user to docker group
REAL_USER=$(get_real_user)
run_sudo usermod -aG docker "$REAL_USER"