xremap: naersk-lib: { pkgs, config, ... }:

let
  cfg = config.services.xremap;
  package = (import ../overlay xremap naersk-lib pkgs { inherit (cfg) withSway withGnome withX11; }).xremap-unwrapped;
in
with pkgs.lib;
{
  imports = [
    ./user-service.nix
    ./system-service.nix
  ];
  options.services.xremap = {
    serviceMode = mkOption {
      type = types.enum [ "user" "system" ];
      default = "system";
      description = ''
        The mode the service will run as.

        Using user serviceMode:
        * Adds user to input group
        * Adds udev rule so that /dev/uinput device is owned by input group
        * Does not set niceness

        Using system serviceMode:
        * Runs xremap as root in a hardened systemd service
        * Sets niceness to -20
      '';
    };
    withSway = mkEnableOption "support for Sway";
    withGnome = mkEnableOption "support for Gnome";
    withX11 = mkEnableOption "support for X11";
    package = mkOption {
      type = types.package;
      default = package;
    };
    config = mkOption {
      type = types.attrs;
      description = "Xremap configuration. See xremap repo for examples";
      default = {
        modmap = [ ];
      };
      example = ''
        {
          modmap = [
            {
              name = "Global",
              remap = {
                CapsLock = "Esc";
                Ctrl_L = "Esc";
              };
            }
          ];
          keymap = [
            {
              name = "Default (Nocturn, etc.)",
              application = {
              not = [ "Google-chrome", "Slack", "Gnome-terminal", "jetbrains-idea"];
              };
              remap = {
                # Emacs basic
                "C-b" = "left";
                "C-f" = "right";
              };
            }
          ];
        }
      '';
    };
    userId = mkOption {
      type = types.int;
      default = 1000;
      description = "User ID that would run Sway IPC socket";
    };
    userName = mkOption {
      type = types.str;
      description = "Name of user logging into graphical session";
    };
    deviceName = mkOption {
      type = types.str;
      description = "Device name which xremap will hook into";
    };
    watch = mkEnableOption "running xremap watching new devices";
  };
}
