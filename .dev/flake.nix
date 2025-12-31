{
  description = "Development / demo flake for xremap";

  inputs = {
    parent.url = ./..;
    # This will reduce the number of `nixpkgs` instances floating around
    # Requires `nix flake update --inputs-from ..`
    # Note that `nixpkgs.follows = "nixpkgs"` will not work, it will cause a loop
    thisNixpkgs.url = "nixpkgs";
    nixpkgs.follows = "thisNixpkgs";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, ... }:
    let
      # This bit of code allows reusing the parent's inputs
      parentInputs = inputs.parent.inputs;
    in
    parentInputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { ... }: # Here be flake-parts-lib if I ever need it
      {
        imports = [
          inputs.devshell.flakeModule
          inputs.treefmt-nix.flakeModule
        ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        perSystem =
          {
            inputs',
            pkgs,
            config,
            ...
          }:
          let
            inherit (pkgs) lib;
          in
          {
            devshells = import ./devshell.nix {
              inherit config;
              inherit (pkgs) lib;
            };

            treefmt = {
              projectRootFile = "flake.nix";
              # When run in CI, will have `treefmt` check the whole repo
              projectRoot = inputs.parent;
              programs = {
                nixfmt.enable = true;
                statix.enable = true;
                deadnix.enable = true;
              };
            };
            apps = {
              demo-wlroots-hyprland = {
                type = "app";
                program = lib.pipe ./demos/wlroots-hyprland.nix [
                  (it: import it { inherit self; })
                  (lib.flip pkgs.callPackage { })
                  (builtins.getAttr "driverInteractive")
                ];
              };
            };

            inherit (inputs'.parent) packages;

            checks = lib.pipe ./checks [
              (lib.fileset.fileFilter (file: file.hasExt "nix"))
              lib.fileset.toList
              (map (it: {
                # Construct a human-readable name
                name = lib.pipe it [
                  builtins.toString
                  builtins.baseNameOf
                  (lib.replaceStrings [ ".nix" ] [ "" ])
                ];
                # Construct the package to be called as a check
                value = lib.pipe it [
                  (it': import it' { inherit self; })
                  (lib.flip pkgs.callPackage { })
                ];
              }))
              builtins.listToAttrs
            ];
          };
        flake = {
          # Re-export so that they can be passed to other parts of the subflake
          inherit (inputs.parent) homeManagerModules;
        };
      }
    );
}
