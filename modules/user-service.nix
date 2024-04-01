{ mkExecStart, configFile }:
{ pkgs, lib, config, ... }:

let
  inherit (lib) optionalString;
  cfg = config.services.xremap;
in
{
  config = lib.mkIf (cfg.enable && cfg.serviceMode == "user") {
    hardware.uinput.enable = true;
    /* services.udev.extraRules = */
    /*   '' */
    /*     KERNEL=="uinput", GROUP="input", MODE="0660" */
    /*   ''; */
    # Uinput group owns the /uinput
    users.groups.uinput.members = [
      cfg.userName
    ];
    # To allow access to /dev/input
    users.groups.input.members = [
      cfg.userName
    ];
    systemd.user.services.xremap = {
      description = "xremap user service";
      path = [ cfg.package ];
      # NOTE: xremap needs DISPLAY:, WAYLAND_DISPLAY: and a bunch of other stuff in the environment to launch graphical applications (launch:)
      # On Gnome after gnome-session.target is up - those variables are populated
      after = lib.mkIf (cfg.withGnome == true) [ "gnome-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        KeyringMode = "private";
        SystemCallArchitectures = [ "native" ];
        RestrictRealtime = true;
        ProtectSystem = true;
        SystemCallFilter = map
          (x: "~@${x}")
          [
            "clock"
            "debug"
            "module"
            "reboot"
            "swap"
            "cpu-emulation"
            "obsolete"
            # NOTE: These two make the spawned processes drop cores
            # "privileged"
            # "resources"
          ];
        LockPersonality = true;
        UMask = "077";
        RestrictAddressFamilies = "AF_UNIX";
        Environment = optionalString cfg.debug "RUST_LOG=debug";
        ExecStart = mkExecStart configFile;
      };
    };
  };
}
