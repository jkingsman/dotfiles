#!/usr/bin/env bash
# Install i3 window manager and configuration

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

REAL_HOME=$(get_real_home)
DOTFILES_DIR="${REAL_HOME}/dotfiles"

# Install i3 and related packages
run_sudo apt update
# i3 basics
run_sudo apt install -y i3-wm i3status i3lock
run_sudo apt install -y dunst # notifications
run_sudo apt install -y xdotool # numlock light
run_sudo apt install -y rofi # menu/launcher
run_sudo apt install -y pasystray # tray audio
run_sudo apt install -y feh # wallpaper etc.
run_sudo apt install -y compton # compositing

# Create i3 config directory
run_as_user mkdir -p "${REAL_HOME}/.config/i3"

# Copy i3 config file
run_as_user cp "${DOTFILES_DIR}/qol/provisioning/i3.config" "${REAL_HOME}/.config/i3/config"

# move i3status into place
mkdir -p ~/.config/i3status
cp /etc/i3status.conf ~/.config/i3status/config

# Check if battery exists
has_battery=false
if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
    has_battery=true
fi

# Comment out battery line if no battery
if [ "$has_battery" = false ]; then
    sed -i 's/^order += "battery all"/#&/' ~/.config/i3status/config
fi

# comment out interfaces if we don't have them
has_ip_for_type() {
    local pattern="$1"
    for iface in $(ip -o link show | awk -F': ' '{print $2}' | grep -E "$pattern"); do
        if ip addr show "$iface" | grep -q 'inet '; then
            return 0
        fi
    done
    return 1
}

# Check wireless interfaces (wlan*, wlp*, wl*)
if ! has_ip_for_type '^(wlan|wlp|wl)'; then
    sed -i 's/^order += "wireless _first_"/#&/' ~/.config/i3status/config
fi

# Check ethernet interfaces (eth*, enp*, eno*, ens*, enx*)
if ! has_ip_for_type '^(eth|enp|eno|ens|enx)'; then
    sed -i 's/^order += "ethernet _first_"/#&/' ~/.config/i3status/config
fi
