#!/usr/bin/env bash
set -euo pipefail

# Get Volume
get_volume() {
    volume=$(pamixer --get-volume)
    if [[ "$volume" -eq "0" ]]; then
        echo "Muted"
    else
        echo "$volume%"
    fi
}

# Get icons
get_icon() {
    current=$(get_volume)
    if [[ "$current" == "Muted" ]]; then
        echo "󰝟"
    elif [[ "${current%\%}" -le 30 ]]; then
        echo "󰕿"
    elif [[ "${current%\%}" -le 60 ]]; then
        echo "󰖀"
    else
        echo "󰕾"
    fi
}

get_micon() {
  current=$(pamixer --get-mute)
  if [[ "$current" == "true" ]]; then
    echo "󰍭"
  else
    echo "󰍬"
  fi
}

# Notify
notify_user() {
    if [[ "$(get_volume)" == "Muted" ]]; then
        notify-send -e -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(get_icon)" "Volume: Muted"
    else
        notify-send -e -h int:value:"$(get_volume | sed 's/%//')" -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(get_icon)" "Volume: $(get_volume)"
    fi
}

# Increase Volume
inc_volume() {
    if [ "$(pamixer --get-mute)" == "true" ]; then
        pamixer -u && notify_user
    fi
    pamixer -i 5 && notify_user
}

# Decrease Volume
dec_volume() {
    if [ "$(pamixer --get-mute)" == "true" ]; then
        pamixer -u && notify_user
    fi
    pamixer -d 5 && notify_user
}

# Toggle Mute
toggle_mute() {
	if [ "$(pamixer --get-mute)" == "false" ]; then
		pamixer -m && notify-send -e -u low -i "$(get_icon)" "Volume Switched OFF"
	elif [ "$(pamixer --get-mute)" == "true" ]; then
		pamixer -u && notify-send -e -u low -i "$(get_icon)" "Volume Switched ON"
	fi
}

# Toggle Mic
toggle_mic() {
	if [ "$(pamixer --default-source --get-mute)" == "false" ]; then
		pamixer --default-source -m && notify-send -e -u low -i "$(get_micon)" "Microphone Switched OFF"
	elif [ "$(pamixer --default-source --get-mute)" == "true" ]; then
		pamixer -u --default-source u && notify-send -e -u low -i "$(get_micon)" "Microphone Switched ON"
	fi
}

# Get Microphone Volume
get_mic_volume() {
    volume=$(pamixer --default-source --get-volume)
    if [[ "$volume" -eq "0" ]]; then
        echo "Muted"
    else
        echo "$volume%"
    fi
}

# Notify for Microphone
notify_mic_user() {
    volume=$(get_mic_volume)
    icon=$(get_micon)
    notify-send -e -h int:value:"$volume" -h "string:x-canonical-private-synchronous:volume_notif" -u low -i "$icon" "Mic-Level: $volume"
}

# Increase MIC Volume
inc_mic_volume() {
    if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
        pamixer --default-source -u && notify_mic_user
    fi
    pamixer --default-source -i 5 && notify_mic_user
}

# Decrease MIC Volume
dec_mic_volume() {
    if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
        pamixer --default-source -u && notify_mic_user
    fi
    pamixer --default-source -d 5 && notify_mic_user
}

pulsemixerRunna ()
{
  pulsui="kitty -T pulsemixer-window pulsemixer"

  # we test for an existing window
  if [[ $(hyprctl clients -j | jq 'any(.[]; .title == "pulsemixer-window")') == "true" ]]; then
    # we test if it's in current workspace
    activeworkspace=$(hyprctl activeworkspace -j | jq -r '.id')
    if [[ $(hyprctl clients -j | jq --arg ws $activeworkspace 'any(.[]; .title == "pulsemixer-window" and .workspace.id == ($ws|tonumber))') == "true" ]]; then
      # kill it
      hyprctl clients -j | \
      jq -r '.[] | .title, .pid' | paste - - | \
      grep pulsemixer-window | \
      cut -f2 | \
      xargs '-d\n' -I{} hyprctl dispatch "killwindow pid:{}"
    else
      # move to active workspace
      hyprctl clients -j | \
      jq -r '.[] | .title, .pid' | paste - - | \
      grep pulsemixer-window | \
      cut -f2 | \
      xargs '-d\n' -I{} hyprctl dispatch "movetoworkspace $activeworkspace,pid:{}"
    fi
    return 0
  fi
  
  # if we make it here, run it ;)
  $pulsui 2>/dev/null &
}

systemd_init ()
{
  while true; do
    echo "$(pactl -f json list | jq '.sinks[].name')"
    echo "$(pactl -f json list | jq '.sources[].name')"
    echo "$(whoami)"
    if [[ $(pactl get-sink-mute $(pactl get-default-sink) | sed 's/Mute: //') == "no" ]];then
      echo 'off' | tee -p '/sys/class/sound/ctl-led/speaker/mode' > /dev/null
    else
      echo 'on' | tee -p '/sys/class/sound/ctl-led/speaker/mode' > /dev/null
    fi
    if [[ $(pactl get-source-mute $(pactl get-default-source) | sed 's/Mute: //') == "no" ]];then
      echo 'off' | tee -p '/sys/class/sound/ctl-led/mic/mode' > /dev/null
    else
      echo 'on' | tee -p '/sys/class/sound/ctl-led/mic/mode' > /dev/null
    fi
    sleep 0.1
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  "TUI")
    pulsemixerRunna
    ;;
  "GET")
    get_volume
    ;;
  "INC")
    inc_volume
    ;;
  "DEC")
    dec_volume
   ;;
  "TOGGLE")
    toggle_mute
    ;;
  "TOGGLE-MIC")
    toggle_mic
    ;;
  "GET-ICON")
    get_icon
    ;;
  "GET-MIC-ICON")
    get_micon
    ;;
  "MIC-INC")
    inc_mic_volume
    ;;
  "MIC-DEC")
    dec_mic_volume
    ;;
  "SYSTEMD-INIT")
    systemd_init
    ;;
  *)
    get_volume
    ;;
  esac
  shift
done    
