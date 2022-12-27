{
  description = "Flake that configures Xremap, a key remapper for Linux";

  inputs = {
    # Nixpkgs will be pinned to unstable to get the latest Rust
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Utils for building Rust stuff
    naersk.url = "github:nmattia/naersk/master";
    # The Rust source for xremap
    xremap = {
      url = "github:k0kubun/xremap?ref=v0.7.13";
      flake = false;
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
  };
  outputs = { self, nixpkgs, naersk, xremap, hyprland }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    rec
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          naersk-lib = pkgs.callPackage naersk { };
        in
        {
          default = (import ./overlay xremap naersk-lib pkgs { }).xremap-unwrapped;
        }
      );
      apps = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          naersk-lib = pkgs.callPackage naersk { };
          package = (import ./overlay xremap naersk-lib pkgs { }).xremap-unwrapped;
        in
        {
          default = {
            type = "app";
            program = "${package}/bin/xremap";
          };
        }
      );
      devShells = forAllSystems
        (system:
          let
            pkgs = nixpkgsFor.${system};
          in
          {
            default =
              with pkgs; mkShell {
                buildInputs = [ cargo rustc rustfmt rustPackages.clippy ];
                RUST_SRC_PATH = rustPlatform.rustLibSrc;
              };
          }
        );

      # See comments in the module
      nixosModules.default = import ./modules xremap naersk;

      nixosConfigurations =
        let
          default_modules = [
            self.nixosModules.default
            ./nixosConfigurations/vm-config.nix
            {
              services.xremap = {
                userName = "alice";
                config = {
                  keymap = [
                    {
                      name = "Test remap a>b in kitty";
                      application = {
                        "only" = "kitty";
                      };
                      remap = {
                        "a" = "b";
                      };
                    }
                    {
                      name = "Test remap c>d everywhere";
                      remap = {
                        "x" = "z";
                      };
                    }
                  ];
                };
              };
            }
          ];
          system = "x86_64-linux";
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          hyprland-system-dev = nixpkgs.lib.nixosSystem {
            inherit pkgs system;
            modules = [
              hyprland.nixosModules.default
              {
                boot.tmpOnTmpfs = true; # To clean out hyprland socket
                networking.hostName = "hyprland-system-dev";
                programs.hyprland = {
                  enable = true;
                };
                services.xremap = {
                  withHypr = true;
                };
              }
            ] ++ default_modules;
          };
          hyprland-user-dev = nixpkgs.lib.nixosSystem {
            inherit pkgs system;
            modules = [
              hyprland.nixosModules.default
              {
                boot.tmpOnTmpfs = true; # To clean out hyprland socket
                networking.hostName = "hyprland-user-dev";
                programs.hyprland = {
                  enable = true;
                };
                services.xremap = {
                  withHypr = true;
                  serviceMode = "user";
                };
              }
            ] ++ default_modules;
          };
          # NOTE: after alice is logged in - need to run systemctl restart xremap.service to pick up the socket
          sway-system-dev = nixpkgs.lib.nixosSystem {
            inherit pkgs system;
            modules = [
              {
                programs.sway.enable = true;
              }
              ./nixosConfigurations/sway-common.nix
            ] ++ default_modules;
          };
        };
    };
}
