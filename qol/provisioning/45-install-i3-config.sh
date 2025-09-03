#!/usr/bin/env bash
# Install i3 window manager and configuration

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DOTFILES_DIR="${HOME}/dotfiles"

# Install i3 and related packages
sudo apt update
# i3 basics
sudo apt install -y i3-wm i3status i3lock xorg # i3 core
sudo apt install -y dunst # notifications
sudo apt install -y xdotool # numlock enable on login
sudo apt install -y rofi # menu/launcher
sudo apt install -y pasystray # tray audio
sudo apt install -y feh # wallpaper set
sudo apt install -y picom # compositing -- don't do much with transparency but good to have
sudo apt install -y xinput # mouse/trackpad management
sudo apt install -y brightnessctl # brightness adjustment
sudo apt install -y flameshot # screenshots

# Create i3 config directory
mkdir -p "${HOME}/.config/i3"

# Copy i3 config file
cp "${DOTFILES_DIR}/qol/provisioning/i3.config" "${HOME}/.config/i3/config"

# move i3status into place
mkdir -p "${HOME}/.config/i3status"
cp /etc/i3status.conf "${HOME}/.config/i3status/config"

# move tap to click and scroll config into place
sudo mkdir -p /etc/X11/xorg.conf.d
sudo cp "${DOTFILES_DIR}/qol/provisioning/90-touchpad.conf" "/etc/X11/xorg.conf.d/90-touchpad.conf"

echo "Xft.dpi: 120" >> ~/.Xresources

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
