{ localFlake, inputs }:
let
  system = "x86_64-linux";
  pkgs = inputs.nixpkgs;
  commonModules = [
    localFlake.nixosModules.default
    ./vm-config.nix
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
              name = "Test remap 9>0 everywhere";
              remap = {
                "9" = "0";
              };
            }
          ];
        };
      };
    }
  ];
  mkDevSystem = { hostName, customModules }: pkgs.lib.nixosSystem {
    inherit system;
    modules = commonModules ++ customModules ++ [{
      networking = { inherit hostName; };
    }];
  };
in
{
  # no-features-system = abort "Tested ad-hoc";
  # no-features-user = abort "Tested ad-hoc";
  sway-system = mkDevSystem
    {
      hostName = "sway-system";
      customModules = [
        # Autologin
        { services.getty.autologinUser = "alice"; }
        # Sway
        {
          programs.sway.enable = true;
        }
        ./sway-common.nix
      ];
    } // { _comment = "After auto-login, run 'sway' and 'sleep 1 && systemctl restart xremap'. Sleep is needed to prevent xremap from capturing extra input."; };
  # sway-user = abort "Tested ad-hoc";
  # gnome-system = abort "Tested ad-hoc";
  gnome-user = mkDevSystem
    {
      hostName = "gnome-user";
      customModules = [
        ./gnome-common.nix
      ];
    } // { _comment = "Enable the xremap Gnome extension manually."; };
  # x11-system = abort "Tested ad-hoc";
  # x11-user = abort "Tested ad-hoc";
  # hypr-system = abort "Not implemented";
  hypr-user = mkDevSystem
    {
      hostName = "hypr-user";
      customModules = [
        # Makes the hyprland socket cleanup easy
        # { boot.tmp.useTmpfs = true; }
        # Autologin
        { services.getty.autologinUser = "alice"; }
        inputs.hyprland.nixosModules.default
        {
          programs.hyprland = {
            package = inputs.hyprland.packages.${system}.default;
            enable = true;
          };
          hardware.opengl.enable = true;
        }
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager =
            {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.alice = { ... }: {
                imports = [ inputs.hyprland.homeManagerModules.default ];
                home.stateVersion = "23.05";
                wayland.windowManager.hyprland =
                  {
                    enable = true;
                    # Makes xremap auto-start with hyprland
                    systemdIntegration = true;
                  };
              };
            };
        }
        { services.xremap = { withHypr = true; serviceMode = "user"; }; }
      ];
    } // { _comment = "Login with the user's password and run 'Hyprland' in tty. Launch Kitty and test."; };
}
