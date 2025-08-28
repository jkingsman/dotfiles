#!/usr/bin/env bash
# Check installed applications

set +ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

check_version() {
  if command -v "$1" &>/dev/null; then
    ver=$("$1" --version 2>/dev/null || "$1" -v 2>/dev/null || "$1" version 2>/dev/null | head -n1)
    echo "✅ $1: $ver"
  else
    echo "❌ $1: not found"
  fi
}

check_presence() {
  if command -v "$1" &>/dev/null; then
    echo "✅ $1: installed"
  else
    echo "❌ $1: not found"
  fi
}

echo "=== Versions ==="
check_version python
check_version python2
check_version python3
check_version java
check_version node
check_version fzf

# ripgrep uses 'rg' as its command
if command -v rg &>/dev/null; then
  ver=$(rg --version | head -n1)
  echo "✅ ripgrep: $ver"
else
  echo "❌ ripgrep: not found"
fi

# fd is just 'fd' on Alpine
if command -v fd &>/dev/null; then
  ver=$(fd --version)
  echo "✅ fd: $ver"
else
  echo "❌ fd: not found"
fi

echo -e "\n=== Presence Checks ==="
for cmd in pyenv pip poetry uv curl ip ifconfig ipconfig vim emacs jq perl npm nvm ruby rvm mvn gradle nginx caddy docker fzf rg fd kitty; do
  check_presence "$cmd"
done
