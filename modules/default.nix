# localFlake and withSystem allow passing flake to the module through importApply
# See https://flake.parts/define-module-in-separate-file.html
{ localFlake, withSystem }:
{ pkgs, lib, config, ... }:
let
  cfg = config.services.xremap;
  localLib = localFlake.localLib { inherit pkgs lib cfg; };
  inherit (localLib) mkExecStart configFile;
in
with lib; {
  imports = [
    (import ./user-service.nix { inherit mkExecStart configFile; })
    (import ./system-service.nix { inherit mkExecStart configFile; })
  ];
  options.services.xremap = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable xremap service";
    };
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
      default = "";
      description = "Device name which xremap will remap. If not specified - xremap will remap all devices.";
    };
    watch = mkEnableOption "running xremap watching new devices";
  } // localLib.commonOptions;
}
