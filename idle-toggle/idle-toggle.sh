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
  echo "Control script for idle toggle to be used by waybar module"
  echo 
  echo "Usage: $0 [WAYBAR|TOGGLE|STATUS|HELP] [OPTIONS]"
  echo 
  echo "ARGS:"
  echo "  WAYBAR                                     Run waybar module"
  echo "  TOGGLE                                     Toggle hypridle on/off"
  echo "  STATUS                                     Print current status"
  echo "  HELP                                       Print this help info."
  echo
  exit 0
}

check4hypridle ()
{
  if [[ $(pgrep hypridle) == "" ]]; then
    echo "{\"class\": \"off\", \"text\": \"󰩑\", \"tooltip\": \"hypridle is not running\"}" | jq --unbuffered --compact-output
  else
    echo "{\"class\": \"on\", \"text\": \"󱥋\", \"tooltip\": \"hypridle is running\"}" | jq --unbuffered --compact-output
  fi
}

togglehypridle ()
{
  if [[ $(pgrep hypridle) == "" ]]; then
    nohup hypridle &
  else
    kill $(pgrep hypridle)
  fi

  check4hypridle
  return 0
}

waybarStatus ()
{
  if ! toolbarState; then
    echo "{}" | jq --unbuffered --compact-output
    return 0
  fi

  check4hypridle
}

waybarExec ()
{
  while true; do
    waybarStatus
    sleep 0.1
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  "TOGGLE")
    togglehypridle
    ;;
  "STATUS")
    echo $(check4hypridle | jq '.tooltip' | sed 's/^"//g' | sed 's/"$//g')
    ;;
  "WAYBAR")
    waybarExec
    ;;
  "HELP")
    help_and_exit
    ;;
  *)
    echo "ERROR: Invalid option detected."
    help_and_exit
    ;;
  esac
  shift
done