#!/bin/bash
set -e

# Update package list and install git
apt-get update
apt-get install -y git sudo

# Create user jack with home directory
useradd -m -s /bin/bash jack

# Add jack to sudoers with no password requirement
echo "jack ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/jack
chmod 0440 /etc/sudoers.d/jack

# Switch to jack user and run provisioning
su - jack -c '
    cd ~
    git clone https://github.com/jkingsman/dotfiles
    cd dotfiles
    NOPYTHON=1 qol/provisioning/provision.sh
'
