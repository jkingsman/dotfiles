#!/usr/bin/env bash

# Run xrandr and capture output
xrandr_output=$(xrandr)

# Extract current resolution
current_line=$(echo "$xrandr_output" | grep "current")
if [[ $current_line =~ current[[:space:]]+([0-9]+)[[:space:]]+x[[:space:]]+([0-9]+) ]]; then
    width="${BASH_REMATCH[1]}"
    height="${BASH_REMATCH[2]}"
    
    # Check if width is less than height (portrait orientation)
    if [ "$width" -lt "$height" ]; then
        sleep 1
        xrandr -o right
        sleep 1
        feh --randomize --bg-fill ~/dotfiles/qol/wallpapers/*
    fi
fi
