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
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
  elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
  elif [ -f /etc/centos-release ]; then
    # Older CentOS
    OS=CentOS
    VER=$(cat /etc/centos-release | sed 's/^.*release //;s/ (Fin.*$//')
  elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    OS=RedHat
    VER=$(cat /etc/redhat-release | sed 's/^.*release //;s/ (Fin.*$//')
  elif [ -f /etc/alpine-release ]; then
    # Alpine Linux
    OS=Alpine
    VER=$(cat /etc/alpine-release)
  else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
  fi

  echo "Detected OS: $OS $VER"
}

# Setup sudo without password for current user
setup_sudo_nopasswd() {
  echo "=== Setting up sudo without password for current user ==="

  case "$OS" in
    "Ubuntu"|"Debian"|*"Linux Mint"*)
      echo "$(whoami) ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$(whoami) > /dev/null
      sudo chmod 0440 /etc/sudoers.d/$(whoami)
      ;;
    "Alpine"*)
      # Alpine might not have sudo installed by default
      if ! command -v sudo &> /dev/null; then
        echo "Installing sudo on Alpine..."
        su -c "apk add sudo"
      fi
      echo "$(whoami) ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$(whoami) > /dev/null
      sudo chmod 0440 /etc/sudoers.d/$(whoami)
      ;;
    "CentOS"|"RedHat"|"Amazon"*)
      echo "$(whoami) ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$(whoami) > /dev/null
      sudo chmod 0440 /etc/sudoers.d/$(whoami)
      ;;
    *)
      echo "Unsupported OS for sudo configuration: $OS"
      exit 1
      ;;
  esac
}

# Install essential packages
install_essentials() {
  echo "=== Installing essential packages ==="

  case "$OS" in
    "Ubuntu"|"Debian"|*"Linux Mint"*)
      sudo apt update
      sudo apt install -y curl openssh-server git build-essential
      ;;
    "Alpine"*)
      sudo apk update
      sudo apk add curl openssh git build-base linux-headers
      ;;
    "CentOS"|"RedHat"|"Amazon"*)
      if command -v dnf &> /dev/null; then
        sudo dnf install -y curl openssh-server git make gcc gcc-c++ kernel-devel
      else
        sudo yum install -y curl openssh-server git make gcc gcc-c++ kernel-devel
      fi
      ;;
    *)
      echo "Unsupported OS for package installation: $OS"
      exit 1
      ;;
  esac
}

# Configure SSH
configure_ssh() {
  echo "=== Configuring SSH ==="
  # Create .ssh directory if it doesn't exist
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh

  # Download authorized keys from GitHub
  echo "=== Downloading authorized keys from GitHub ==="
  curl -s https://github.com/jkingsman.keys > ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys

  # Configure SSH server for security
  echo "=== Securing SSH server configuration ==="
  sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  sudo tee /etc/ssh/sshd_config > /dev/null << EOF
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

  # Restart SSH service (handling different service managers and service names)
  echo "=== Restarting SSH service ==="

  # Check which SSH service name exists
  SSH_SERVICE=""
  if systemctl list-units --all | grep -q "sshd.service"; then
    SSH_SERVICE="sshd"
  elif systemctl list-units --all | grep -q "ssh.service"; then
    SSH_SERVICE="ssh"
  fi

  # Restart using the appropriate method and service name
  if [ -n "$SSH_SERVICE" ] && command -v systemctl &> /dev/null; then
    echo "Using systemctl to restart $SSH_SERVICE service"
    sudo systemctl restart $SSH_SERVICE
  elif command -v service &> /dev/null; then
    # Try both service names with the service command
    if service sshd status &>/dev/null; then
      echo "Using service command to restart sshd"
      sudo service sshd restart
    elif service ssh status &>/dev/null; then
      echo "Using service command to restart ssh"
      sudo service ssh restart
    else
      echo "SSH service not found with 'service' command"
    fi
  elif [ -f /etc/init.d/sshd ]; then
    echo "Using init.d script to restart sshd"
    sudo /etc/init.d/sshd restart
  elif [ -f /etc/init.d/ssh ]; then
    echo "Using init.d script to restart ssh"
    sudo /etc/init.d/ssh restart
  else
    echo "WARNING: Unable to restart SSH service - it may need to be restarted manually"
    echo "Common service names are 'ssh' or 'sshd'"
  fi
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
    "Ubuntu"|"Debian"|*"Linux Mint"*)
      sudo apt update
      sudo apt upgrade -y
      sudo apt autoremove -y
      ;;
    "Alpine"*)
      sudo apk update
      sudo apk upgrade
      ;;
    "CentOS"|"RedHat"|"Amazon"*)
      if command -v dnf &> /dev/null; then
        sudo dnf upgrade -y
        sudo dnf autoremove -y
      else
        sudo yum update -y
        sudo yum clean all
      fi
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
    "Ubuntu"|"Debian"|*"Linux Mint"*|"CentOS"|"RedHat"|"Amazon"*)
      ./configure --prefix=/usr/local && make && sudo make install
      ;;
    "Alpine"*)
      # Alpine might need additional dependencies
      sudo apk add ncurses-dev readline-dev
      ./configure --prefix=/usr/local && make && sudo make install
      ;;
    *)
      echo "Proceeding with generic bash compilation..."
      ./configure --prefix=/usr/local && make && sudo make install
      ;;
  esac

  # Add the new shell to the list of legit shells
  echo "=== Adding new Bash to allowed shells ==="
  echo "/usr/local/bin/bash" | sudo tee -a /etc/shells

  # Change the shell for the user
  echo "=== Changing default shell to new Bash ==="
  sudo chsh -s /usr/local/bin/bash $(whoami)
}

# Clone dotfiles and run unpack
setup_dotfiles() {
  echo "=== Cloning dotfiles repository ==="
  cd ~
  git clone git@github.com:jkingsman/dotfiles.git

  echo "=== Running dotfiles unpack script ==="
  cd ~
  ~/dotfiles/.unpack
}

# Install Python 3.10
install_python() {
  echo "=== Installing Python 3.10 ==="

  case "$OS" in
    "Ubuntu"|"Debian"|*"Linux Mint"*)
      # For Ubuntu 20.04+ and newer Debian
      if command -v add-apt-repository &> /dev/null; then
        sudo apt update
        sudo apt install -y software-properties-common
        sudo add-apt-repository -y ppa:deadsnakes/ppa
        sudo apt update
        sudo apt install -y python3.10 python3.10-venv python3.10-dev python3-pip
        sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
      else
        # Fallback for older Debian without PPAs
        echo "Building Python 3.10 from source..."
        sudo apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget
        cd /tmp
        wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz
        tar -xf Python-3.10.0.tgz
        cd Python-3.10.0
        ./configure --enable-optimizations
        make -j $(nproc)
        sudo make altinstall
        # Create symlinks
        sudo ln -sf /usr/local/bin/python3.10 /usr/local/bin/python3
        sudo ln -sf /usr/local/bin/pip3.10 /usr/local/bin/pip3
      fi
      ;;
    "Alpine"*)
      # Alpine typically uses apk
      if apk info -e python3 | grep -q '3.10'; then
        sudo apk add python3 py3-pip
      else
        # Build from source if 3.10 is not in repositories
        sudo apk add build-base zlib-dev readline-dev openssl-dev libffi-dev
        cd /tmp
        wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz
        tar -xf Python-3.10.0.tgz
        cd Python-3.10.0
        ./configure --enable-optimizations --prefix=/usr/local
        make -j $(nproc)
        sudo make altinstall
        # Create symlinks
        sudo ln -sf /usr/local/bin/python3.10 /usr/local/bin/python3
        sudo ln -sf /usr/local/bin/pip3.10 /usr/local/bin/pip3
      fi
      ;;
    "CentOS"|"RedHat"|"Amazon"*)
      # CentOS/RHEL typically uses dnf/yum
      if command -v dnf &> /dev/null; then
        sudo dnf install -y epel-release
        sudo dnf install -y python3.10 python3.10-devel python3-pip || {
          # If package not found, build from source
          sudo dnf install -y gcc zlib-devel openssl-devel readline-devel libffi-devel
          cd /tmp
          wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz
          tar -xf Python-3.10.0.tgz
          cd Python-3.10.0
          ./configure --enable-optimizations
          make -j $(nproc)
          sudo make altinstall
          # Create symlinks
          sudo ln -sf /usr/local/bin/python3.10 /usr/local/bin/python3
          sudo ln -sf /usr/local/bin/pip3.10 /usr/local/bin/pip3
        }
      else
        # Older CentOS with yum
        sudo yum install -y epel-release
        sudo yum install -y python3.10 python3.10-devel python3-pip || {
          # If package not found, build from source
          sudo yum install -y gcc zlib-devel openssl-devel readline-devel libffi-devel
          cd /tmp
          wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz
          tar -xf Python-3.10.0.tgz
          cd Python-3.10.0
          ./configure --enable-optimizations
          make -j $(nproc)
          sudo make altinstall
          # Create symlinks
          sudo ln -sf /usr/local/bin/python3.10 /usr/local/bin/python3
          sudo ln -sf /usr/local/bin/pip3.10 /usr/local/bin/pip3
        }
      fi
      ;;
    *)
      echo "Unsupported OS for Python installation: $OS"
      echo "Attempting generic Python build..."
      cd /tmp
      wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz
      tar -xf Python-3.10.0.tgz
      cd Python-3.10.0
      ./configure --enable-optimizations
      make -j $(nproc)
      sudo make altinstall
      # Create symlinks
      sudo ln -sf /usr/local/bin/python3.10 /usr/local/bin/python3
      sudo ln -sf /usr/local/bin/pip3.10 /usr/local/bin/pip3
      ;;
  esac

  # Verify installation
  if command -v python3.10 &> /dev/null; then
    echo "Python 3.10 installed successfully: $(python3.10 --version)"
  elif command -v python3 &> /dev/null && python3 --version | grep -q "3.10"; then
    echo "Python 3.10 installed successfully: $(python3 --version)"
  else
    echo "WARNING: Python 3.10 installation may not have succeeded. Please check manually."
  fi
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
