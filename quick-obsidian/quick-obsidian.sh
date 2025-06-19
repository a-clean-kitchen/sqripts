#!/usr/bin/env bash
set -euo pipefail

scriptDir=$(dirname "$(dirname "${BASH_SOURCE[0]}/bin")")
rofiConfig="${scriptDir}/config/config.rasi"
vault="$(echo $1 | sed 's/ /%20/g')"

dmeneww() {
  declare i=${*:-$(</dev/stdin)}
  echo "$(echo -e "$i" | rofi -i -dmenu -theme $rofiConfig)" || exit 0
}

options="DAILY\nLAUNCH\n"
case "$(echo -e "$options" | dmeneww)" in
    DAILY)
        notify-send "Opening Daily Note"
        xdg-open "obsidian://adv-uri?open?vault=$vault&daily=true"
        ;;
    LAUNCH)
        notify-send "Opening LaunchPad.md"
        xdg-open "obsidian://adv-uri?vault=$vault&filepath=LaunchPad.md"
        ;;
esac
