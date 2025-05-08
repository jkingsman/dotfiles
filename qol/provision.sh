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
  elif command -v lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
    OS=Debian
    read -r VER < /etc/debian_version
  elif [ -f /etc/centos-release ] || [ -f /etc/redhat-release ]; then
    FILE=/etc/centos-release
    [ -f /etc/redhat-release ] && FILE=/etc/redhat-release
    OS=$(awk '{print $1}' "$FILE")
    VER=$(sed -E 's/.*release ([0-9.]+).*/\1/' "$FILE")
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
    Ubuntu|Debian|*"Linux Mint"*|CentOS|RedHat|Amazon*)
      ;;
    Alpine*)
      command -v sudo >/dev/null 2>&1 || { echo "Installing sudo on Alpine..."; su -c "apk add sudo"; }
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
    Ubuntu|Debian|*"Linux Mint"*)
      sudo apt update
      sudo apt install -y curl openssh-server git build-essential
      ;;
    Alpine*)
      sudo apk update
      sudo apk add curl openssh git build-base linux-headers
      ;;
    Amazon*|CentOS|RedHat)
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
  curl -s https://github.com/jkingsman.keys > ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys

  echo "=== Securing SSH server configuration ==="
  sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  sudo bash -c 'cat > /etc/ssh/sshd_config' << EOF
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
  cat > ~/.ssh/id_rsa
  chmod 600 ~/.ssh/id_rsa
  echo "Private key added."
}

# Update all packages
update_packages() {
  echo "=== Updating all packages ==="

  case "$OS" in
    Ubuntu|Debian|*"Linux Mint"*)
      sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
      ;;
    Alpine*)
      sudo apk update && sudo apk upgrade
      ;;
    CentOS|RedHat|Amazon*)
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
    Ubuntu|Debian|*"Linux Mint"*|CentOS|RedHat|Amazon*|*)
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
  source ~/.bashrc_personal
}

# Install Python 3.10
install_python() {
  PYTHON_VERSION=${1:-3.12.0}
  echo "=== Installing Python $PYTHON_VERSION via pyenv ==="

  install_pyenv_dependencies() {
    case "$OS" in
      Ubuntu|Debian|*"Linux Mint"*)
        sudo apt update
        sudo apt install -y make build-essential libssl-dev zlib1g-dev \
          libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
          libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
        ;;
      Alpine*)
        sudo apk add build-base libffi-dev openssl-dev zlib-dev bzip2-dev readline-dev sqlite-dev xz-dev tk-dev
        ;;
      CentOS|RedHat|Amazon*)
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

    # Function to check if a command exists
    check_command() {
        local cmd=$1
        local group=$2
        local extra_check=$3

        printf "%-15s: " "$cmd"
        if command -v "$cmd" &>/dev/null; then
            echo -e "\033[32m✓ Installed\033[0m"
            # If extra_check is provided, run it
            if [ -n "$extra_check" ]; then
                eval "$extra_check"
            fi
        else
            echo -e "\033[31m✗ Not installed\033[0m"
        fi
    }

    # Function to check Python versions
    check_python_versions() {
        printf "  %-15s: " "Versions"

        # Check for Python 2
        if command -v python &>/dev/null; then
            PY2_VER=$(python --version 2>&1 | grep -oP '(?<=Python )[0-9]+\.[0-9]+\.[0-9]+')
            echo -n "Python $PY2_VER "
        fi

        # Check for Python 3
        if command -v python3 &>/dev/null; then
            PY3_VER=$(python3 --version 2>&1 | grep -oP '(?<=Python )[0-9]+\.[0-9]+\.[0-9]+')
            echo -n "Python3 $PY3_VER "
        fi

        # Check for specific Python versions (3.6 to 3.11)
        for ver in {6..11}; do
            if command -v python3.$ver &>/dev/null; then
                PY_SPECIFIC=$(python3.$ver --version 2>&1 | grep -oP '(?<=Python )[0-9]+\.[0-9]+\.[0-9]+')
                echo -n "Python $PY_SPECIFIC "
            fi
        done
        echo ""
    }

    # Function to check network tools
    check_network_tools() {
        echo -e "\n\033[1mNetwork Tools\033[0m"
        check_command "curl" "network"

        # Check for IP command or alternatives
        printf "%-15s: " "ip/ifconfig"
        if command -v ip &>/dev/null; then
            echo -e "\033[32m✓ Installed (ip)\033[0m"
        elif command -v ifconfig &>/dev/null; then
            echo -e "\033[32m✓ Installed (ifconfig)\033[0m"
        else
            echo -e "\033[31m✗ Not installed\033[0m"
        fi

        check_command "sshd" "network"
    }

    # Function to check text editors
    check_editors() {
        echo -e "\n\033[1mText Editors\033[0m"
        check_command "vim" "editors"
    }

    # Function to check Python ecosystem
    check_python_ecosystem() {
        echo -e "\n\033[1mPython Ecosystem\033[0m"
        check_command "python" "python" "check_python_versions"
        check_command "pip" "python"
        check_command "poetry" "python"
        check_command "uv" "python"
    }

    # Function to check JS ecosystem
    check_js_ecosystem() {
        echo -e "\n\033[1mJavaScript Ecosystem\033[0m"
        check_command "node" "js"
        check_command "npm" "js"
        check_command "nvm" "js"
    }

    # Function to check Java ecosystem
    check_java_ecosystem() {
        echo -e "\n\033[1mJava Ecosystem\033[0m"
        check_command "java" "java" "java -version 2>&1 | head -n 1 | awk '{print \"  Version      : \" \$0}'"
        check_command "maven" "java" "mvn --version 2>&1 | head -n 1 | awk '{print \"  Version      : \" \$3}'"
        check_command "gradle" "java" "gradle --version 2>&1 | grep Gradle | head -n 1 | awk '{print \"  Version      : \" \$2}'"
    }

    # Function to check Ruby ecosystem
    check_ruby_ecosystem() {
        echo -e "\n\033[1mRuby Ecosystem\033[0m"
        check_command "rvm" "ruby"
    }

    # Function to check web servers
    check_web_servers() {
        echo -e "\n\033[1mWeb Servers\033[0m"
        check_command "nginx" "webserver" "nginx -v 2>&1 | awk '{print \"  Version      : \" \$3}'"
        check_command "caddy" "webserver" "caddy version 2>&1 | head -n 1 | awk '{print \"  Version      : \" \$1}'"
    }

    # Function to check container platforms
    check_containers() {
        echo -e "\n\033[1mContainer Platforms\033[0m"
        check_command "docker" "container" "docker --version | awk '{print \"  Version      : \" \$3}'"

        # Check if Docker Compose is available
        if command -v docker &>/dev/null; then
            if docker compose version &>/dev/null; then
                printf "  %-15s: " "Docker Compose"
                echo -e "\033[32m✓ Installed\033[0m"
                docker compose version 2>&1 | head -n 1 | awk '{print "  Version      : " $3}'
            fi
        fi
    }

    # Run all checks
    check_network_tools
    check_editors
    check_python_ecosystem
    check_js_ecosystem
    check_java_ecosystem
    check_ruby_ecosystem
    check_web_servers
    check_containers
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
