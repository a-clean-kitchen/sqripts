{
  description = "A very basic flake";

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
            theScript = (pkgs.writeScriptBin name (builtins.readFile scriptPath)).overrideAttrs(old: {
              buildCommand = "${old.buildCommand}\n patchShebangs $out";
            });
          in pkgs.symlinkJoin {
            inherit name;
            paths = [ theScript ] ++ buildInputs;
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
          };
      in rec {
        defaultPackage = bundleScript "draggin" (with pkgs; [ cowsay ]) ./default.sh;
        packages = {
          volume = bundleScript "volume" (with pkgs; [ pamixer libnotify hyprland jq kitty ]) ./volume-control/volume-control.sh;
          bluetoof = bundleScript "bluetoof" (with pkgs; [ bluez hyprland jq kitty bluetui ]) ./bluetooth-waybar-module/bluetooth.sh;
          brightness = bundleScript "brightness" (with pkgs; [ brightnessctl libnotify ]) ./brightness-control/brightness-control.sh;
          idle-toggle = bundleScript "idle-toggle" (with pkgs; [ hypridle ]) ./idle-toggle/idle-toggle.sh;
          impala-runna = bundleScript "impala-runna" (with pkgs; [ impala hyprland jq kitty ]) ./impala-runna/impala-runna.sh;
        };
        apps = let
          program = name: { type = "app"; program = "${self.packages."${system}"."${name}"}/bin/${name}"; };
        in {
          default = {
            type = "app";
            program = "${self.defaultPackage."${system}"}/bin/draggin";
          };
          volume = program "volume";
          bluetoof = program "bluetoof";
          brightness = program "brightness";
          idle-toggle = program "idle-toggle";
          impala-runna = program "impala-runna";
        };
      }
    );
}
