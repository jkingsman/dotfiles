#!/usr/bin/env bash
# Install essential packages

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo apt update
sudo apt install -y \
  wget \
  curl \
  git \
  vim \
  build-essential \
  gcc \
  gnupg \
  g++ \
  make \
  perl \
  ruby \
  openssh-client \
  openssh-server \
  dnsutils \
  iputils-ping \
  htop \
  lsof \
  file \
  zip \
  unzip \
  tar \
  gzip \
  bzip2 \
  p7zip-full \
  ca-certificates \
  gnupg \
  apt-transport-https \
  sudo \
  fontconfig

# check if string "Raspberry Pi" is in /proc/cpuinfo and set SW rendering on kitty
if grep -q "Raspberry Pi" /proc/cpuinfo; then
  wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo dpkg -i google-chrome-stable_current_amd64.deb
  sudo apt-get install -f
  google-chrome --version

  sudo apt install -y firefox-esr
fi
