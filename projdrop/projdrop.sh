#!/usr/bin/env bash
set -euo pipefail

scriptDir=$(dirname "$(dirname "${BASH_SOURCE[0]}/bin")")
rofiConfig="${scriptDir}/config/config.rasi"

allProjects=$(find ~/wksp -name .git -type d -prune | sed 's/\/.git//')


project=$(echo -e "$allProjects" | rofi -theme-str "inputbar { background-image: url('~/Pictures/wallpapers/flower.jpg', width); }" \
    -dmenu \
    -theme $rofiConfig) 

[ -z "$project" ] && exit

kitty -T "project:$project" --detach -d "$project" --hold
