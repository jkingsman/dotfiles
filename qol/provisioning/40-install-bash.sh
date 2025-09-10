#!/usr/bin/env bash
# Install newer version of Bash

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cp "${SCRIPT_DIR}/data/bash-5.2.tar.gz" /tmp/bash-5.2.tar.gz
cd /tmp
tar xzf bash-5.2.tar.gz
cd bash-5.2

./configure --prefix=/usr/local
make
sudo make install

# Find shells file
if [ -f /etc/shells ]; then
  SHELLS_FILE="/etc/shells"
elif [ -f /private/etc/shells ]; then
  SHELLS_FILE="/private/etc/shells"
else
  SHELLS_FILE=""
fi

# Add to shells file if found
if [ -n "$SHELLS_FILE" ]; then
  if ! grep -q "^/usr/local/bin/bash$" "$SHELLS_FILE"; then
    sudo bash -c "echo /usr/local/bin/bash >> $SHELLS_FILE"
  fi
fi

# Change shell for current user
if command -v chsh >/dev/null 2>&1; then
  sudo chsh -s /usr/local/bin/bash "$USER"
else
  sudo usermod -s /usr/local/bin/bash "$USER"
fi
