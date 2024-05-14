{ pkgs, ... }:
{
  services.xserver = {
    enable = true;
    displayManager = {
      gdm.enable = true;
      autoLogin = {
        enable = true;
        user = "alice";
      };
    };
    desktopManager.gnome.enable = true;
  };
  services.xremap = {
    withGnome = true;
    serviceMode = "user";
  };
  environment.systemPackages = builtins.attrValues {
    inherit (pkgs.gnomeExtensions) appindicator xremap;
    inherit (pkgs) kitty wev libnotify;
    inherit (pkgs.xorg) xev;
  };
  services.udev.packages = builtins.attrValues { inherit (pkgs.gnome) gnome-settings-daemon; };
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
}
