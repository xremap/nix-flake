/**
  A demo of `xremap` running in hyprland.

  Uses home manager module.

  To run the demo:

  1. Start kitty and foot (see hyprland config below for bindings)
  2. Hit `alt-a` and `alt-9` to see changed bindings
*/
{ self, ... }:
{ lib, pkgs, config, ... }:
{
  # Hyprland-specific
  hardware.graphics.enable = true;
  home-manager.users.alice = {
    home.stateVersion = "25.11";
    wayland.windowManager.hyprland.enable = true;
    wayland.windowManager.hyprland.extraConfig = ''
      bind = SUPER CTRL, k, exec, ${lib.getExe pkgs.kitty}
      bind = SUPER CTRL, f, exec, ${lib.getExe pkgs.foot}
    '';
  };
  services.greetd = {
    enable = true;
    settings = rec {
      # Effectively auto-login
      default_session = initial_session;
      initial_session = {
        command = "${lib.getExe config.home-manager.users.alice.wayland.windowManager.hyprland.package}";
        user = "alice";
      };
    };
  };

  # Looks like `uinput` group membership is required in this config
  # For some reason, this is not a problem in NixOS test...
  users.users.alice.extraGroups = [ "uinput" ];

  # Imports
  imports = [
    ../common/common-setup.nix
    ../common/setup-uinput.nix
    self.inputs.home-manager.nixosModules.home-manager
  ];

  # Consequent runs of this VM fail without the following.
  # https://github.com/nix-community/home-manager/issues/6364
  home-manager.useUserPackages = true;
  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  # `xremap` config is here
  home-manager.users.alice = {
    imports = [ self.homeManagerModules.default ];
    services.xremap = {
      enable = true;
      withWlroots = true;
      config = {
        keymap = [
          {
            name = "Remap 'alt-a' to 'b' in kitty";
            application = {
              "only" = "kitty";
            };
            remap = {
              "ALT-a" = "b";
            };
          }
          {
            name = "Remap 'alt-9' to '0' everywhere";
            remap = {
              "ALT-9" = "0";
            };
          }
        ];
      };
    };
  };
}
