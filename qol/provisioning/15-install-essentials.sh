#!/usr/bin/env bash
# Install essential packages

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo apk update
sudo apk add --no-cache \
  wget \
  curl \
  git \
  vim \
  build-base \
  gcc \
  g++ \
  make \
  perl \
  ruby \
  openssh-client \
  openssh-server \
  bind-tools \
  iputils \
  htop \
  lsof \
  file \
  zip \
  unzip \
  tar \
  gzip \
  bzip2 \
  p7zip \
  ca-certificates \
  gnupg \
  sudo \
  fontconfig
