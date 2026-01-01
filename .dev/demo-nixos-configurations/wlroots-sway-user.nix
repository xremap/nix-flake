/**
  A demo of `xremap` running on sway.

  Uses NixOS module and runs in `user` mode.

  To run the demo:

  1. Start kitty and foot (see sway config below for bindings)
  2. Hit `alt-a` and `alt-9` to see changed bindings
*/
{ self, ... }:
{
  pkgs,
  lib,
  config,
  ...
}:
{
  # Sway setup
  programs.sway.enable = true;

  environment.etc."sway/config.d/test".text = ''
    bindsym super+ctrl+k exec ${pkgs.kitty}/bin/kitty
    bindsym super+ctrl+f exec ${pkgs.foot}/bin/foot
  '';

  # Auto-login
  services.greetd = {
    enable = true;
    settings = rec {
      default_session = initial_session;
      initial_session = {
        command = "${lib.getExe config.programs.sway.package}";
        user = "alice";
      };
    };
  };

  # Imports
  imports = [
    ../common/common-setup.nix
    self.nixosModules.default
  ];

  services.xremap = {
    enable = true;
    withWlroots = true;
    serviceMode = "user";
    userName = "alice";
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
}
