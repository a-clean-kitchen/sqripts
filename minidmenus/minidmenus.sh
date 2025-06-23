#!/usr/bin/env bash

scriptDir=$(dirname "$(dirname "${BASH_SOURCE[0]}/bin")")
rofiConfig="${scriptDir}/config/config.rasi"

help_and_exit ()
{
    echo
    echo "Control script many mini dmenus"
    echo
    echo "Usage: $0 [ROFI|HELP] [OPTIONS]"
    echo
    echo "ARGS:"
    echo "  HELP                                     Print this help info."
    echo "  DMENUS                                   Run a dmenu selector."
    echo "  KILL                                     Kill a process."
    echo
    exit 0
}


dmeneww() {
  declare i=${*:-$(</dev/stdin)}
  echo "$(echo -e "$i" | rofi -i -dmenu -theme $rofiConfig)" || exit 0
}

killMenu() {
    procs="$(ps -u $USER -o pid,comm,%cpu,%mem | tail -n +2)"
    pid="$(echo -e "$procs" | dmeneww | awk '{print $1}')"
    if [ -z "$pid" ]; then
        exit 0
    fi
    kill $pid
}

dmenus="KILL"

dmenuSelector() {
  function=$(echo -e "$dmenus" | dmeneww)
  $0 $function
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    DMENUS)
      dmenuSelector
      ;;
    HELP)
      help_and_exit
      ;;
    KILL)
      killMenu
      ;;
    *)
      help_and_exit
      ;;
  esac
  shift
done