{
  description = "Flake that configures Xremap, a key remapper for Linux";

  inputs = {
    # Nixpkgs will be pinned to unstable to get the latest Rust
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    treefmt-nix.url = "github:numtide/treefmt-nix";

    # Utils for building Rust stuff

    crane.url = "github:ipetkov/crane";

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
      url = "github:k0kubun/xremap?ref=v0.14.8";
      flake = false;
    };
  };
  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, flake-parts-lib, ... }:
      let
        inherit (flake-parts-lib) importApply;
      in
      {
        imports = [
          inputs.flake-parts.flakeModules.easyOverlay
          inputs.treefmt-nix.flakeModule
        ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        perSystem =
          { config, pkgs, ... }:
          let
            craneLib = inputs.crane.mkLib pkgs;
            inherit (pkgs) lib;
          in
          {
            packages = import ./overlay {
              inherit (inputs) xremap;
              inherit craneLib pkgs;
            };
            # This way all packages get immediately added to the overlay except for the one called literally called "default"
            overlayAttrs = builtins.removeAttrs config.packages [ "default" ];

            treefmt = {
              projectRootFile = "flake.nix";
              programs = {
                nixfmt.enable = true;
                statix.enable = true;
                deadnix.enable = true;
              };
            };
            checks = import ./checks { inherit self pkgs lib; };
          };
        flake = {
          nixosModules.default = importApply ./modules {
            localFlake = self;
            inherit withSystem;
          };
          homeManagerModules.default = importApply ./homeManagerModules { localFlake = self; };
          localLib = import ./lib { localFlake = self; };
        };
      }
    );
}
