#!/usr/bin/env bash
# Provisioning Script for Ubuntu and Debian

# Exit on error
set -e

# Ensure script is run as a regular user, not root
if [ "$(id -u)" -eq 0 ]; then
  echo "This script should be run as a regular user, not as root!"
  exit 1
fi

# Setup sudo without password for current user
setup_sudo_nopasswd() {
  echo "=== Setting up sudo without password for current user ==="
  SUDOERS_FILE="/etc/sudoers.d/$(whoami)"
  echo "$(whoami) ALL=(ALL) NOPASSWD:ALL" | sudo tee "$SUDOERS_FILE" >/dev/null
  sudo chmod 0440 "$SUDOERS_FILE"
}

# Install essential packages
install_essentials() {
  echo "=== Installing essential packages ==="
  sudo apt update
  sudo apt install -y curl openssh-server git build-essential
}

configure_ssh() {
  echo "=== Configuring SSH ==="

  mkdir -p ~/.ssh && chmod 700 ~/.ssh

  echo "=== Downloading authorized keys from GitHub ==="
  curl -s https://github.com/jkingsman.keys >~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys

  echo "=== Securing SSH server configuration ==="
  sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  sudo bash -c 'cat > /etc/ssh/sshd_config' <<EOF
# SSH Server Configuration
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Authentication
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Other settings
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

  echo "=== Restarting SSH service ==="
  sudo systemctl restart ssh || sudo service ssh restart
}

# Add private key
add_private_key() {
  echo "=== Setting up SSH private key ==="
  echo "Please paste your private key content (Ctrl+D when finished):"
  cat >~/.ssh/id_rsa
  chmod 600 ~/.ssh/id_rsa
  echo "Private key added."
}

# Update all packages
update_packages() {
  echo "=== Updating all packages ==="
  sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
}

# Install newer Bash
install_bash() {
  echo "=== Installing newer version of Bash ==="

  cd /tmp
  curl -O http://ftp.gnu.org/gnu/bash/bash-5.2.tar.gz
  tar xzf bash-5.2.tar.gz
  cd bash-5.2

  ./configure --prefix=/usr/local && make && sudo make install

  echo "=== Adding new Bash to allowed shells ==="
  grep -qx "/usr/local/bin/bash" /etc/shells || echo "/usr/local/bin/bash" | sudo tee -a /etc/shells

  echo "=== Changing default shell to new Bash ==="
  USERNAME=$(whoami)
  sudo chsh -s /usr/local/bin/bash "$USERNAME"
}

# Clone dotfiles and run unpack
setup_dotfiles() {
  echo "=== Cloning dotfiles repository ==="
  DOTFILES_DIR=~/dotfiles
  if [ -d "$DOTFILES_DIR" ]; then
    echo "Dotfiles directory already exists, pulling latest changes..."
    git -C "$DOTFILES_DIR" pull
  else
    git clone https://github.com/jkingsman/dotfiles.git "$DOTFILES_DIR"
  fi

  echo "=== Running dotfiles unpack script ==="
  chmod -R +x "$DOTFILES_DIR"
  (cd "$DOTFILES_DIR" && ./.unpack)
}

# Install Python 3.12
install_python() {
  PYTHON_VERSION="3.12.0"
  echo "=== Installing Python $PYTHON_VERSION via pyenv ==="

  # Install pyenv dependencies for Debian/Ubuntu
  echo "=== Installing pyenv build dependencies ==="
  sudo apt update
  sudo apt install -y make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

  if ! command -v pyenv >/dev/null; then
    echo "=== Installing pyenv ==="
    curl https://pyenv.run | bash

    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
  else
    echo "pyenv already installed: $(pyenv --version)"
  fi

  export PATH="$HOME/.pyenv/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"

  if pyenv versions | grep -q "$PYTHON_VERSION"; then
    echo "Python $PYTHON_VERSION already installed with pyenv."
  else
    pyenv install "$PYTHON_VERSION"
  fi

  pyenv global "$PYTHON_VERSION"
  echo "Python $(python --version) installed and set as default via pyenv."
}

# Install command-line productivity tools
install_cli_tools() {
  echo "=== Installing command-line productivity tools ==="

  # Install fzf, ripgrep, and fd-find via apt
  sudo apt update
  sudo apt install -y fzf ripgrep fd-find
}

# Install quality-of-life packages
install_qol_packages() {
  echo "=== Installing quality-of-life packages ==="

  # Install UV (Python package installer)
  echo "=== Installing UV ==="
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.cargo/bin:$PATH"

  # Install Poetry (Python dependency management)
  echo "=== Installing Poetry ==="
  curl -sSL https://install.python-poetry.org | python3 -
  export PATH="$HOME/.local/bin:$PATH"

  # Install NVM (Node Version Manager)
  echo "=== Installing NVM ==="
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

  # Install Node.js v22 using NVM
  echo "=== Installing Node.js v22 ==="
  nvm install 22
  nvm use 22
  nvm alias default 22

  # Install Yarn for JS dependency management
  echo "=== Installing Yarn ==="
  npm install -g yarn

  # Install Java (OpenJDK 21)
  echo "=== Installing Java (OpenJDK 21) ==="
  sudo apt update
  sudo apt install -y openjdk-21-jdk

  # Install Docker
  echo "=== Installing Docker ==="
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Add current user to docker group
  sudo usermod -aG docker $USER
  echo "NOTE: You'll need to log out and back in for docker group membership to take effect"
}

check_apps() {
  echo "System Tools and Applications Check"
  echo "===================================="

  check_version() {
    if command -v "$1" &>/dev/null; then
      ver=$("$1" --version 2>/dev/null || "$1" -v 2>/dev/null || "$1" version 2>/dev/null)
      echo "✅ $1: $ver"
    else
      echo "❌ $1: not found"
    fi
  }

  check_presence() {
    if command -v "$1" &>/dev/null; then
      echo "✅ $1: installed"
    else
      echo "❌ $1: not found"
    fi
  }

  echo "=== Versions ==="
  check_version python
  check_version python2
  check_version python3
  check_version java
  check_version node
  check_version fzf
  # ripgrep uses 'rg' as its command
  if command -v rg &>/dev/null; then
    ver=$(rg --version | head -n1)
    echo "✅ ripgrep: $ver"
  else
    echo "❌ ripgrep: not found"
  fi
  check_version fd
  # fd-find installs as 'fdfind' on Debian/Ubuntu
  if command -v fdfind &>/dev/null; then
    ver=$(fdfind --version)
    echo "✅ fd-find: $ver"
  else
    echo "❌ fd-find: not found"
  fi

  echo -e "\n=== Presence Checks ==="
  for cmd in pyenv pip poetry uv curl ip ifconfig ipconfig vim emacs jq perl npm nvm ruby rvm mvn gradle nginx caddy docker fzf rg fdfind; do
    check_presence "$cmd"
  done
}

# Main execution
main() {
  setup_sudo_nopasswd
  install_essentials
  configure_ssh
  # add_private_key  # Commented out - uncomment if you want to add private key
  update_packages
  install_python
  install_bash
  setup_dotfiles
  install_cli_tools
  install_qol_packages
  check_apps

  echo "=== Provisioning complete! ==="
  echo "You should log out and back in for all changes to take effect."
  echo "NOTE: Docker group membership requires a logout/login to take effect."
}

main
exec ${SHELL} -l
