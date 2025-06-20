#!/usr/bin/env bash
set -euo pipefail

scriptDir=$(dirname "$(dirname "${BASH_SOURCE[0]}/bin")")
rofiConfig="${scriptDir}/config/config.rasi"
vault="$(echo $2 | sed 's/ /%20/g')"

dmeneww() {
  declare i=${*:-$(</dev/stdin)}
  echo "$(echo -e "$i" | rofi -i -dmenu -theme $rofiConfig)" || exit 0
}
dmenuLaunch() {
  options="NEW\nDAILY\nCLIPBOARD\nLAUNCH\n"
  case "$(echo -e "$options" | dmeneww)" in
    NEW)
      notify-send "Creating New Quick Note"
      FILENAME=$(:| rofi -i -dmenu \
        -theme $rofiConfig \
        -theme-str "entry { placeholder: \"Filename...\"; width: inherit; expand: true; padding: 5px; }" \
        -theme-str "window { width: 15%; padding: 5px; }" \
        -theme-str "mainbox { children: [ \"entry\" ]; }")
      if [ -z "$FILENAME" ]; then
        FILENAME="Untitled"
      fi
      xdg-open "obsidian://adv-uri?vault=$vault&mode=new&filepath=$FILENAME.md"
      ;;
    DAILY)
      notify-send "Opening Daily Note"
      xdg-open "obsidian://adv-uri?open?vault=$vault&daily=true"
      ;;
    CLIPBOARD)
      clipboardAppendToDaily
      ;;
    LAUNCH)
      notify-send "Opening LaunchPad.md"
      xdg-open "obsidian://adv-uri?vault=$vault&filepath=LaunchPad.md"
      ;;
  esac
}

clipboardAppendToDaily() {
  notify-send "Adding Clipboard to Daily Note"
  xdg-open "obsidian://adv-uri?open?vault=$vault&mode=append&daily=true&clipboard=true"
}

case "$1" in
  LAUNCH)
    dmenuLaunch
    ;;
  CLIPBOARD)
    clipboardAppendToDaily
    ;;
  *)
    echo "Whoops"
    ;;
esac