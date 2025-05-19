#!/usr/bin/env bash
set -euo pipefail


# I use a special file to determine whether some modules should stay hidden
toolbarState ()
{
  LOCK=$XDG_DATA_HOME/expand.lock
  if [ -f "$LOCK" ]; then
      return 0
  else 
      return 1
  fi
}

help_and_exit() 
{
  echo 
  echo "Control script for bluetooth to be used by waybar module"
  echo 
  echo "Usage: $0 [TUI|HELP] [OPTIONS]"
  echo 
  echo "ARGS:"
  echo "  WAYBAR                                     Run waybar module"
  echo "  TUI                                        Open bluetui in a kitty window"
  echo "  TOGGLE                                     Toggle bluetooth on/off"
  echo "  STATUS                                     Print current status"
  echo "  HELP                                       Print this help info."
  echo
  exit 0
}

bluetuiRunna ()
{
  blueui="kitty -T bluetui-window bluetui"

  # we test for an existing window
  if [[ $(hyprctl clients -j | jq 'any(.[]; .title == "bluetui-window")') == "true" ]]; then
    # we test if it's in current workspace
    activeworkspace=$(hyprctl activeworkspace -j | jq -r '.id')
    if [[ $(hyprctl clients -j | jq --arg ws $activeworkspace 'any(.[]; .title == "bluetui-window" and .workspace.id == ($ws|tonumber))') == "true" ]]; then
      # kill it
      hyprctl clients -j | \
      jq -r '.[] | .title, .pid' | paste - - | \
      grep bluetui-window | \
      cut -f2 | \
      xargs '-d\n' -I{} hyprctl dispatch "killwindow pid:{}"
    else
      # move to active workspace
      hyprctl clients -j | \
      jq -r '.[] | .title, .pid' | paste - - | \
      grep bluetui-window | \
      cut -f2 | \
      xargs '-d\n' -I{} hyprctl dispatch "movetoworkspace $activeworkspace,pid:{}"
    fi
    return 0
  fi
  
  # if we make it here, run it ;)
  $blueui 2>/dev/null &
}

currentlyConnectedDevice ()
{
  deviceName=$(bluetoothctl info | grep "Name:" | sed 's/Name: //' | awk '{$1=$1};1')
  echo $deviceName
}

bluetoothStatus ()
{
  if ! toolbarState; then
    echo "{}" | jq --unbuffered --compact-output
    return 0
  fi

  if [[ $(bluetoothctl show $(bluetoothctl list | awk '{print $2}')| grep "Powered: yes") == "" ]]; then
    echo "{\"class\": \"off\", \"text\": \"󰂲 \", \"tooltip\": \"off\"}" | jq --unbuffered --compact-output
  else
    if [[ -n $(bluetoothctl info | grep "Connected: yes") ]]; then
      echo "{\"class\": \"on\", \"text\": \"󰂱 \", \"tooltip\": \"$(currentlyConnectedDevice)\"}" | jq --unbuffered --compact-output
    else
      echo "{\"class\": \"on\", \"text\": \"󰂯 \", \"tooltip\": \"on but not connected\"}" | jq --unbuffered --compact-output
    fi
  fi
}

waybarExec ()
{
  while true; do
    bluetoothStatus
    sleep 0.1
  done
}

bluetoothToggle ()
{
  # check if it's running
  if [[ $(bluetoothctl show $(bluetoothctl list | awk '{print $2}') | grep "Powered: yes") == "" ]]; then
    bluetoothctl power on
  else
    bluetoothctl power off
  fi

  bluetoothStatus
  return 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    TUI)
      bluetuiRunna
      ;;
    TOGGLE)
      bluetoothToggle
      ;;
    STATUS)
      bluetoothStatus
      ;;
    WAYBAR)
      waybarExec
      ;;
    HELP)
      help_and_exit
      ;;
    *)
      echo "ERROR: Invalid option detected."
      help_and_exit
      ;;
  esac
  shift
done
