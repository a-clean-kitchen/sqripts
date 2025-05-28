#!/usr/bin/env bash

notification_timeout=1000

# Get brightness
get_backlight() {
	echo $(brightnessctl -m | cut -d, -f4)
}

# Set icon
set_icon() {
	current=$(get_backlight | sed 's/%//')

	if   [ "$current" -le "0" ]; then
		icon="󰹐"
    elif [ "$current" -le "10" ]; then
		icon="󱩎"
	elif [ "$current" -le "20" ]; then
		icon="󱩏"
	elif [ "$current" -le "30" ]; then
		icon="󱩐"
	elif [ "$current" -le "40" ]; then
		icon="󱩑"
	elif [ "$current" -le "50" ]; then
		icon="󱩒"
	elif [ "$current" -le "60" ]; then
		icon="󱩓"
	elif [ "$current" -le "70" ]; then
		icon="󱩔"
	elif [ "$current" -le "80" ]; then
		icon="󱩕"
	elif [ "$current" -le "90" ]; then
		icon="󱩖"
	else
		icon="󰛨"
	fi
}

# Notify
notify_user() {
	current=$(get_backlight | sed 's/%//')
	notify-send -e -h string:x-canonical-private-synchronous:brightness_notif -h int:value:$current -u low -i "$icon" "Brightness : $current%"
}

# Change brightness
change_backlight() {
	brightnessctl set "$1" && set_icon && notify_user
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  "GET")
    get_backlight
    ;;
  "INC")
    change_backlight "+10%"
    ;;
  "DEC")
    change_backlight "10%-"
    ;;
  *)
    get_backlight
    ;;
  esac
  shift
done
