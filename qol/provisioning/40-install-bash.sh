#!/usr/bin/env bash
# Install newer version of Bash

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

cd /tmp
curl -O http://ftp.gnu.org/gnu/bash/bash-5.2.tar.gz
tar xzf bash-5.2.tar.gz
cd bash-5.2

./configure --prefix=/usr/local
make
run_sudo make install

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
    run_sudo bash -c "echo /usr/local/bin/bash >> $SHELLS_FILE"
  fi
fi

# Change shell for real user
REAL_USER=$(get_real_user)
if command -v chsh >/dev/null 2>&1; then
  run_sudo chsh -s /usr/local/bin/bash "$REAL_USER"
else
  run_sudo usermod -s /usr/local/bin/bash "$REAL_USER"
fi