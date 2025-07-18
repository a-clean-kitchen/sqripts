{
  description = "A bunch of scripts I WILL be using";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        bundleScript = name: buildInputs: scriptPath: 
          let
            lib = pkgs.lib;
            scriptPath = ./. + "/${name}/${name}.sh";
            theScript = (pkgs.writeScriptBin name (builtins.readFile scriptPath)).overrideAttrs(old: {
              buildCommand = "${old.buildCommand}\n patchShebangs $out";
            });

            configPath = builtins.derivation {
              inherit system;
              inherit (pkgs) toybox;
              name = "${name}-config";
              src = ./. + "/${name}";
              builder = (pkgs.writeShellScript "${name}-config-builder" ''
                $toybox/bin/mkdir -p $out/bin/config
                if [ ! -d "$src/config" ]; then
                  exit 0
                fi
                $toybox/bin/cp -r $src/config/* $out/bin/config
              '');
            };
          in pkgs.symlinkJoin {
            inherit name;
            paths = [ theScript configPath ] ++ buildInputs;
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin;";
          };
      in rec {
        defaultPackage = bundleScript "draggin" (with pkgs; [ cowsay ]) ./default.sh;
        packages = {
          # desktop/dotfiles
          volume = bundleScript "volume" (with pkgs; [ pulseaudioFull pamixer sudo libnotify hyprland jq kitty ]) ./volume;
          bluetooth = bundleScript "bluetooth" (with pkgs; [ bluez hyprland jq kitty bluetui ]) ./bluetooth;
          brightness = bundleScript "brightness" (with pkgs; [ brightnessctl libnotify ]) ./brightness;
          btop-runna = bundleScript "btop-runna" (with pkgs; [ btop hyprland jq kitty ]) ./btop-runna;
          idle-toggle = bundleScript "idle-toggle" (with pkgs; [ hypridle ]) ./idle-toggle;
          impala-runna = bundleScript "impala-runna" (with pkgs; [ impala hyprland jq kitty ]) ./impala-runna;
          rebuild-nixos = bundleScript "rebuild-nixos" (with pkgs; [ nix systemdMinimal ]) ./rebuild-nixos;

          # rofi/dmenus
          launcher = bundleScript "launcher" (with pkgs; [ rofi-wayland ]) ./launcher;
          minidmenus = bundleScript "minidmenus" (with pkgs; [ rofi-wayland ]) ./minidmenus;
          projdrop = bundleScript "projdrop" (with pkgs; [ rofi-wayland kitty ]) ./projdrop;
          screenshot = bundleScript "screenshot" (with pkgs; [ hyprshot libnotify killall rofi-wayland wf-recorder ]) ./screenshot;
          quick-obsidian = bundleScript "quick-obsidian" (with pkgs; [ rofi-wayland ]) ./quick-obsidian;
        };
        apps = let
          program = name: { type = "app"; program = "${self.packages."${system}"."${name}"}/bin/${name}"; };
        in {
          default = {
            type = "app";
            program = "${self.defaultPackage."${system}"}/bin/draggin";
          };
          volume = program "volume";
          bluetooth = program "bluetooth";
          brightness = program "brightness";
          screenshot = program "screenshot";
          btop-runna = program "btop-runna";
          idle-toggle = program "idle-toggle";
          quick-obsidian = program "quick-obsidian";
          minidmenus = program "minidmenus";
          impala-runna = program "impala-runna";
          projdrop = program "projdrop";
        };
      }
    );
}
