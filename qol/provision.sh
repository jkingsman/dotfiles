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

  echo -e "\n=== Presence Checks ==="
  for cmd in pyenv pip poetry uv curl ip ifconfig ipconfig vim emacs jq perl npm nvm ruby rvm mvn gradle nginx caddy docker; do
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
  check_apps

  exec ${SHELL} -l
}

main
exec ${SHELL} -l
