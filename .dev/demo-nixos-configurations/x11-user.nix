/**
  A demo of `xremap` running in X11.

  To run the demo:

  1. Launch standard terminal and kitty
  2. Hit `alt-a` and `alt-9` to see changed bindings
*/
{ self, ... }:
{ pkgs, ... }:
{
  # X11 setup
  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = "alice";
  };

  environment.systemPackages = [
    pkgs.kitty
  ];
  imports = [
    ../common/common-setup.nix
    self.nixosModules.default
  ];

  services.xremap = {
    enable = true;
    withX11 = true;
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
