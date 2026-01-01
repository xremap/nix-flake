/**
  A demo of `xremap` running in KDE.

  Uses NixOS module and runs in `user` mode.

  Note that this demo is fairly large space-wise and KDE is not the fastest DE
  when it comes to starting/stopping disposable environments.

  To run the demo:

  1. Start kitty and foot
  2. Hit `alt-a` and `alt-9` to see changed bindings
*/
{ self, ... }:
{ pkgs, ... }:
{
  # KDE setup
  # Source: https://wiki.nixos.org/wiki/KDE
  services.xserver.enable = true;
  services.displayManager = {
    sddm.enable = true;
    sddm.wayland.enable = true;
    autoLogin = {
      enable = true;
      user = "alice";
    };
  };
  services.desktopManager.plasma6.enable = true;

  environment.systemPackages = [
    pkgs.kitty
    pkgs.foot
  ];

  # Imports
  imports = [
    ../common/common-setup.nix
    ../common/qemu-graphics.nix
    self.nixosModules.default
  ];

  services.xremap = {
    enable = true;
    withKDE = true;
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
