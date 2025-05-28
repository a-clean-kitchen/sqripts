#!/usr/bin/env bash
set -euo pipefail

scriptDir=$(dirname "$(dirname "${BASH_SOURCE[0]}/bin")")
screenshotDir=~/Pictures/Screenshots
screenrecordDir=~/Videos/Recordings

screenshotFile="${screenshotDir}/$(date '+%y%m%d-%H%M-%S').png"
screenrecordFile="${screenrecordDir}/$(date '+%y%m%d-%H%M-%S').mkv"


[ -d "$screenshotDir" ] || mkdir -pv "$screenshotDir"
[ -d "$screenrecordDir" ] || mkdir -pv "$screenrecordDir"

rofiConfig="${scriptDir}/config/config.rasi"

help_and_exit ()
{
    echo
    echo "Control script for screenshots and recordings"
    echo
    echo "Usage: $0 [ROFI|HELP] [OPTIONS]"
    echo
    echo "ARGS:"
    echo "  ROFI                                     Open rofi menu"
    echo "  PRINTSCREEN                              Take screenshot"
    echo "  HELP                                     Print this help info."
    echo
    exit 0
}



rofiCmd () 
{
  list_col=$1
  list_row=$2
  win_width=$3
	rofi -theme-str "window {width: $win_width;}" \
		-theme-str "listview {columns: $list_col; lines: $list_row;}" \
		-dmenu \
		-markup-rows \
		-theme $rofiConfig
}

runModePicker () 
{
    video="󰨜"
    picture=""

    # test for ./config/config.rasi
    if [ ! -f "$rofiConfig" ]; then
        ls -la "$scriptDir"
        echo "ERROR: $rofiConfig not found"
        exit 1
    fi
    
    rofiOpt="$video\n$picture"
    rofi=$(echo -e "$rofiOpt" | rofiCmd 1 2 120)
    [ -z "$rofi" ] && exit

    case "$rofi" in
      $video)
        runRecordAudioPicker
        ;;
      $picture)
        runScreenshotModePicker
        ;;
      *)
        help_and_exit
        ;;
    esac
}

runRecordAudioPicker ()
{
  withAudio="󰕾"
  withoutAudio="󰸈"

  rofiOpt="$withAudio\n$withoutAudio"
  rofi=$(echo -e "$rofiOpt" | rofiCmd 1 2 120)
  [ -z "$rofi" ] && exit

  case "$rofi" in
    $withAudio)
      recordWithAudio
      ;;
    $withoutAudio)
      recordWithoutAudio
      ;;
    *)
      help_and_exit
      ;;
  esac
}

runScreenshotModePicker () 
{
  region="󰒉"
  full="󰍹"
  window=""

  rofiOpt="$region\n$full\n$window"
  rofi=$(echo -e "$rofiOpt" | rofiCmd 1 3 120)
  [ -z "$rofi" ] && exit

  case "$rofi" in
    $region)
      screenshot region
      ;;
    $full)
      screenshot output
      ;;
    $window)
      screenshot window
      ;;
    *)
      help_and_exit
      ;;
  esac
}

screenshot ()
{
    hyprshot -m "$1" -o $screenshotDir -f $(date '+%y%m%d-%H%M-%S').png
    notify-send "Screenshot saved to $screenshotFile"
    wl-copy < $screenshotFile &
}

recordWithAudio ()
{
    wf-recorder -a -f "$screenrecordFile"
    notify-send "Screen recording saved to $screenrecordFile"
}

recordWithoutAudio ()
{
    wf-recorder -f "$screenrecordFile"
    notify-send "Screen recording saved to $screenrecordFile"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    ROFI)
      runModePicker
      ;;
    PRINTSCREEN)
      screenshot output
      ;;
    *)
      help_and_exit
      ;;
  esac
  shift
done    