{
  description = "Flake that configures Xremap, a key remapper for Linux";

  inputs = {
    # Nixpkgs will be pinned to unstable to get the latest Rust
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
    # Utils for building Rust stuff
    naersk.url = "github:nmattia/naersk/master";
    # The Rust source for xremap
    xremap = {
      url = "github:k0kubun/xremap?ref=v0.8.5";
      flake = false;
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
  };
  outputs =
    inputs@{ flake-parts
    , self
    , ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, flake-parts-lib, ... }:
      let
        inherit (flake-parts-lib) importApply;
      in
      {
        imports = [
          inputs.devshell.flakeModule
        ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        perSystem = { self', inputs', pkgs, system, ... }:
          let
            naersk-lib = pkgs.callPackage inputs.naersk { };
          in
          {
            formatter = pkgs.nixpkgs-fmt;
            packages = import ./overlay { inherit (inputs) xremap; inherit naersk-lib pkgs; };
            devshells.default = {
              env = [
                {
                  name = "RUST_SRC_PATH";
                  value = pkgs.rustPlatform.rustLibSrc;
                }
              ];
              commands = [
                {
                  help = "Build xremap (no features)";
                  name = "build-xremap-no-features";
                  command = "nix build .#";
                }
                {
                  help = "Build xremap with features one by one";
                  name = "test-build-all-features";
                  command = ''
                    set -euo pipefail

                    features=( "gnome" "hypr" "sway" "x11" )

                    for feature in "''${features[@]}"; do
                      echo "Building feature $feature"
                      nix build .#xremap-''${feature}
                      echo "Build successful"
                    done
                  '';
                }
              ];
              packages = builtins.attrValues {
                inherit (pkgs) cargo rustc rustfmt;
                inherit (pkgs.rustPackages) clippy;
              };
            };
          };
        flake = {
          # nixosModules = {
          #   nixosModules.default = importApply ./modules { localFlake = self; inherit withSystem; };
          # };
        };
      }
    );
}
