#!/usr/bin/env bash
set -e


THEHOSTNAME=$1
DOTFILESPATH=$2

git -C $DOTFILESPATH add --intent-to-add --all

if ! nixos-rebuild build --show-trace --flake $DOTFILESPATH#$THEHOSTNAME; then
  echo "Error: NixOS rebuild failed" >&2
  exit 1
fi

resultDir="$DOTFILESPATH/result"
pathToConfig=$(readlink -f $resultDir)
profile=/nix/var/nix/profiles/system

sudo nix-env -p "$profile" --set "$pathToConfig"

# Stole this from the original nixos-rebuild script, but basically
# We use systemd-run to protect against PTY failures/network
# disconnections during rebuild.
# See: https://github.com/NixOS/nixpkgs/issues/39118
cmd=(
  "systemd-run"
  "-E" "LOCALE_ARCHIVE" # Will be set to new value early in switch-to-configuration script, but interpreter starts out with old value
  "-E" "NIXOS_INSTALL_BOOTLOADER="
  "--collect"
  "--no-ask-password"
  "--pipe"
  "--quiet"
  "--service-type=exec"
  "--unit=nixos-rebuild-switch-to-configuration"
  "--wait"
  "sudo"
  "$pathToConfig/bin/switch-to-configuration"
  "switch"
)


if ! sudo "''${cmd[@]}"; then
  # Switch failed
  exit 1
else
  # Switch succeeded
  echo "$pathToConfig"
fi 

# if PWD is not $DOTFILESPATH, delete the ./result directory that gets built
if [ "$(pwd)" != "$DOTFILESPATH" ]; then
  rm -rf ./result
fi
