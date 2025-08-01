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
