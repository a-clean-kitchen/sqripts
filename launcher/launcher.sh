scriptDir=$(dirname "$(dirname "${BASH_SOURCE[0]}/bin")")
rofiConfig="${scriptDir}/config/config.rasi"

rofi -theme-str "inputbar { background-image: url('~/Pictures/wallpapers/office.jpg', width); }" \
    -show drun \
    -theme $rofiConfig