{
  description = "Flake that configures Xremap, a key remapper for Linux";

  inputs = {
    # Nixpkgs will be pinned to unstable to get the latest Rust
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
    # Utils for building Rust stuff

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # fenix = {
    #   url = "github:nix-community/fenix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   inputs.rust-analyzer-src.follows = "";
    # };
    # advisory-db = {
    #   url = "github:rustsec/advisory-db";
    #   flake = false;
    # };

    # The Rust source for xremap
    xremap = {
      url = "github:k0kubun/xremap?ref=v0.8.13";
      flake = false;
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
    home-manager.url = "github:nix-community/home-manager";
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
          inputs.flake-parts.flakeModules.easyOverlay
        ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        perSystem = { config, self', inputs', pkgs, system, ... }:
          let
            craneLib = inputs.crane.lib.${system};
            inherit (pkgs) lib;
          in
          {
            formatter = pkgs.nixpkgs-fmt;
            packages = import ./overlay { inherit (inputs) xremap; inherit craneLib pkgs; };
            # This way all packages get immediately added to the overlay except for the one called literally called "default"
            overlayAttrs = builtins.removeAttrs config.packages [ "default" ];
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

                    features=( "gnome" "hypr" "sway" "x11" "wlroots" "kde" )

                    for feature in "''${features[@]}"; do
                      echo "Building feature $feature"
                      nix build .#xremap-''${feature}
                      echo "Build successful"
                    done
                  '';
                }
                {
                  help = "SSH into the dev VM. Disregards the known hosts file";
                  name = "vm-ssh";
                  command = ''ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -p 64022 alice@localhost'';
                }
              ]
              ++
              (
                # Construct runners for all development VMs
                let
                  definedVMs = self.nixosConfigurations;
                  namesOfVMs = builtins.attrNames definedVMs;
                  getVMcomment = vmName:
                    if builtins.hasAttr "_comment" definedVMs.${vmName}
                    then definedVMs.${vmName}._comment
                    else "";
                in
                map
                  (nixosSystem: {
                    help = "Run VM for testing ${nixosSystem}";
                    name = "vm-run-${nixosSystem}";
                    command = ''
                      echo "Launching VM"
                      echo "${getVMcomment nixosSystem}"
                      nix run .#nixosConfigurations.${nixosSystem}.config.system.build.vm
                    '';
                  })
                  namesOfVMs
              );
              packages = builtins.attrValues {
                inherit (pkgs) cargo rustc rustfmt;
                inherit (pkgs.rustPackages) clippy;
              };
            };

            checks = import ./checks { inherit self pkgs lib; };
          };
        flake = {
          nixosModules.default = importApply ./modules { localFlake = self; inherit withSystem; };
          homeManagerModules.default = importApply ./homeManagerModules { localFlake = self; inherit withSystem; };
          # nixosConfigurations = import ./nixosConfigurations { localFlake = self; inherit inputs; }; # TODO: restore
          localLib = import ./lib { localFlake = self; };
        };
      }
    );
}
