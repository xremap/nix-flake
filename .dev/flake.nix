{
  description = "Development / demo flake for xremap";

  inputs = {
    parent.url = ./..;
    devshell.url = "github:numtide/devshell";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
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
        imports = [ inputs.devshell.flakeModule ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        perSystem =
          {
            inputs',
            pkgs,
            ...
          }:
          let
            inherit (pkgs) lib;
          in
          {
            devshells.default = {
              commands = [ ];
            };

            apps = {
              wlroots-hyprland-demo = {
                type = "app";
                program = lib.pipe ./demos/wlroots-hyprland.nix [
                  (it: import it { inherit self; })
                  (lib.flip pkgs.callPackage { })
                  (builtins.getAttr "driverInteractive")
                ];
              };
            };

            packages = inputs'.parent.packages;

            checks = lib.pipe ./checks [
              (lib.fileset.fileFilter (file: file.hasExt "nix"))
              (lib.fileset.toList)
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
              (builtins.listToAttrs)
            ];
          };
        flake = {
          # Re-export so that they can be passed to `packages`
          inherit (inputs.parent) homeManagerModules;
        };
      }
    );
}
