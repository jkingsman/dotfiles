#!/usr/bin/env bash
# Multi-OS Provisioning Script for Ubuntu, Debian, Alpine Linux, CentOS/Amazon Linux

# Exit on error
set -e

# Ensure script is run as a regular user, not root
if [ "$(id -u)" -eq 0 ]; then
  echo "This script should be run as a regular user, not as root!"
  exit 1
fi

# Detect OS
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    [ "$OS" = "Red Hat Enterprise Linux" ] && OS="RedHat"
  elif command -v lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
    [ "$OS" = "RedHatEnterpriseServer" ] && OS="RedHat"
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
    [ "$OS" = "RedHatEnterpriseServer" ] && OS="RedHat"
  elif [ -f /etc/debian_version ]; then
    OS=Debian
    read -r VER < /etc/debian_version
  elif [ -f /etc/centos-release ]; then
    read -r LINE < /etc/centos-release
    OS=CentOS
    VER=$(echo "$LINE" | sed -E 's/.*release ([0-9.]+).*/\1/')
  elif [ -f /etc/redhat-release ]; then
    read -r LINE < /etc/redhat-release
    OS=RedHat
    VER=$(echo "$LINE" | sed -E 's/.*release ([0-9.]+).*/\1/')
  elif [ -f /etc/alpine-release ]; then
    OS=Alpine
    read -r VER < /etc/alpine-release
  else
    OS=$(uname -s)
    VER=$(uname -r)
  fi
  echo "Detected OS: $OS $VER"
}


# Setup sudo without password for current user
setup_sudo_nopasswd() {
  echo "=== Setting up sudo without password for current user ==="
  SUDOERS_FILE="/etc/sudoers.d/$(whoami)"

  case "$OS" in
  Ubuntu | Debian | *"Linux Mint"* | CentOS | RedHat | Amazon*) ;;
  Alpine*)
    command -v sudo >/dev/null 2>&1 || {
      echo "Installing sudo on Alpine..."
      su -c "apk add sudo"
    }
    ;;
  *)
    echo "Unsupported OS for sudo configuration: $OS"
    exit 1
    ;;
  esac

  echo "$(whoami) ALL=(ALL) NOPASSWD:ALL" | sudo tee "$SUDOERS_FILE" >/dev/null
  sudo chmod 0440 "$SUDOERS_FILE"
}

# Install essential packages
install_essentials() {
  echo "=== Installing essential packages ==="

  case "$OS" in
  Ubuntu | Debian | *"Linux Mint"*)
    sudo apt update
    sudo apt install -y curl openssh-server git build-essential
    ;;
  Alpine*)
    sudo apk update
    sudo apk add curl openssh git build-base linux-headers
    ;;
  Amazon* | CentOS | RedHat)
    PKG_MGR=$(command -v dnf >/dev/null 2>&1 && echo dnf || echo yum)

    if [[ "$OS" == Amazon* ]]; then
      # Amazon Linux 2023: skip installing curl to avoid conflicts
      echo "Amazon Linux detected: skipping curl install (curl-minimal already provided)"
      PACKAGES="openssh-server git make gcc gcc-c++ kernel-devel util-linux-user"
    else
      PACKAGES="curl openssh-server git make gcc gcc-c++ kernel-devel util-linux-user"
    fi

    sudo $PKG_MGR install -y $PACKAGES
    ;;
  *)
    echo "Unsupported OS for package installation: $OS"
    exit 1
    ;;
  esac
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
  SERVICE_NAME=""

  for candidate in ssh sshd; do
    if systemctl status "$candidate" &>/dev/null; then
      SERVICE_NAME=$candidate
      sudo systemctl restart "$SERVICE_NAME" && return
    elif service "$candidate" status &>/dev/null; then
      SERVICE_NAME=$candidate
      sudo service "$SERVICE_NAME" restart && return
    elif [ -x "/etc/init.d/$candidate" ]; then
      SERVICE_NAME=$candidate
      sudo "/etc/init.d/$SERVICE_NAME" restart && return
    fi
  done

  echo "WARNING: Unable to restart SSH service automatically. Please restart manually."
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

  case "$OS" in
  Ubuntu | Debian | *"Linux Mint"*)
    sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
    ;;
  Alpine*)
    sudo apk update && sudo apk upgrade
    ;;
  CentOS | RedHat | Amazon*)
    PKG_MGR=$(command -v dnf >/dev/null 2>&1 && echo dnf || echo yum)
    sudo $PKG_MGR upgrade -y
    [ "$PKG_MGR" = "dnf" ] && sudo dnf autoremove -y || sudo yum clean all
    ;;
  *)
    echo "Unsupported OS for package updates: $OS"
    ;;
  esac
}

# Install newer Bash
install_bash() {
  echo "=== Installing newer version of Bash ==="

  cd /tmp
  curl -O http://ftp.gnu.org/gnu/bash/bash-5.2.tar.gz
  tar xzf bash-5.2.tar.gz
  cd bash-5.2

  case "$OS" in
  Alpine*)
    sudo apk add ncurses-dev readline-dev
    ;;
  Ubuntu | Debian | *"Linux Mint"* | CentOS | RedHat | Amazon* | *)
    # no extra dependencies for these
    ;;
  esac

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

# Install Python 3.10
install_python() {
  PYTHON_VERSION="3.12.0"
  echo "=== Installing Python $PYTHON_VERSION via pyenv ==="

  install_pyenv_dependencies() {
    case "$OS" in
    Ubuntu | Debian | *"Linux Mint"*)
      sudo apt update
      sudo apt install -y make build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
      ;;
    Alpine*)
      sudo apk add build-base libffi-dev openssl-dev zlib-dev bzip2-dev readline-dev sqlite-dev xz-dev tk-dev
      ;;
    CentOS | RedHat | Amazon*)
      PKG_MGR=$(command -v dnf >/dev/null 2>&1 && echo dnf || echo yum)
      sudo $PKG_MGR install -y gcc make zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel \
        openssl-devel xz xz-devel libffi-devel wget
      ;;
    *)
      echo "Unsupported OS for automatic dependency install. Please install pyenv build dependencies manually."
      ;;
    esac
  }

  if ! command -v pyenv >/dev/null; then
    echo "=== Installing pyenv ==="
    curl https://pyenv.run | bash

    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
  else
    echo "pyenv already installed: $(pyenv --version)"
  fi

  install_pyenv_dependencies

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
  detect_os
  setup_sudo_nopasswd
  install_essentials
  configure_ssh
  # add_private_key
  update_packages
  install_python
  install_bash
  setup_dotfiles
  check_apps

  echo "=== Provisioning complete! ==="
  echo "You should log out and back in for all changes to take effect."
}

main
exec ${SHELL} -l
