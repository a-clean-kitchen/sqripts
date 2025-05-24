#!/usr/bin/env bash
set -euo pipefail

btopui="kitty -T btop-window btop"

# we test for an existing window
if [[ $(hyprctl clients -j | jq 'any(.[]; .title == "btop-window")') == "true" ]]; then
    # we test if it's in current workspace
    activeworkspace=$(hyprctl activeworkspace -j | jq -r '.id')
    if [[ $(hyprctl clients -j | jq --arg ws $activeworkspace 'any(.[]; .title == "btop-window" and .workspace.id == ($ws|tonumber))') == "true" ]]; then
        # kill it
        hyprctl clients -j | \
        jq -r '.[] | .title, .pid' | paste - - | \
        grep btop-window | \
        cut -f2 | \
        xargs '-d\n' -I{} hyprctl dispatch "killwindow pid:{}"
    else
        # move to active workspace
        hyprctl clients -j | \
        jq -r '.[] | .title, .pid' | paste - - | \
        grep btop-window | \
        cut -f2 | \
        xargs '-d\n' -I{} hyprctl dispatch "movetoworkspace $activeworkspace,pid:{}"
    fi
exit 0
fi

# if we make it here, run it ;)
$btopui 2>/dev/null &