#!/usr/bin/env bash
# Configure SSH

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

REAL_HOME=$(get_real_home)
SSH_DIR="${REAL_HOME}/.ssh"

run_as_user mkdir -p "$SSH_DIR"
run_as_user chmod 700 "$SSH_DIR"

# Download authorized keys from GitHub
run_as_user curl -s https://github.com/jkingsman.keys > "${SSH_DIR}/authorized_keys"
run_as_user chmod 600 "${SSH_DIR}/authorized_keys"

# Backup existing SSH config
run_sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Create new SSH config
run_sudo bash -c 'cat > /etc/ssh/sshd_config' <<EOF
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

# Restart SSH service
run_sudo systemctl restart ssh || run_sudo service ssh restart