/**
  A demo of `xremap` running in Gnome.

  To run the demo:

  1. Launch standard terminal and kitty
  2. Hit `alt-a` and `alt-9` to see changed bindings
*/
{ self, ... }:
{ pkgs, ... }:
{
  # Gnome setup
  services.xserver = {
    enable = true;
  };
  services.desktopManager = {
    gnome.enable = true;
  };
  services.displayManager = {
    gdm.enable = true;
    autoLogin = {
      enable = true;
      user = "alice";
    };
  };

  # Enable xremap gnome extension
  systemd.user.services.enable-xremap-extension = {
    description = "Run a one-shot command upon user login";
    path = [ ];
    wantedBy = [ "graphical-session.target" ];
    script = ''
      /run/current-system/sw/bin/gnome-extensions enable xremap@k0kubun.com
    '';
  };

  environment.systemPackages = [
    pkgs.kitty
    pkgs.gnomeExtensions.appindicator
    pkgs.gnomeExtensions.xremap
  ];
  services.udev.packages = builtins.attrValues { inherit (pkgs) gnome-settings-daemon; };

  imports = [
    ../common/common-setup.nix
    ../common/qemu-graphics.nix
    self.nixosModules.default
  ];

  services.xremap = {
    enable = true;
    withGnome = true;
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
