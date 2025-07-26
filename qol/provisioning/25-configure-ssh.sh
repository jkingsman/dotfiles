#!/usr/bin/env bash
# Configure SSH

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

SSH_DIR="${HOME}/.ssh"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Download authorized keys from GitHub
curl -s https://github.com/jkingsman.keys > "${SSH_DIR}/authorized_keys"
chmod 600 "${SSH_DIR}/authorized_keys"

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