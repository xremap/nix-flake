{ localFlake, withSystem }:
{ config, pkgs, lib, ... }:
let
  cfg = config.services.xremap;
  commonModuleObject = import ../modules/common.nix { inherit pkgs lib cfg localFlake; };
  inherit (commonModuleObject) configFile;
in
{
  options.services.xremap = commonModuleObject.commonOptions;
  config = {
    systemd.user.services.xremap = {
      Unit = {
        Description = "xremap service";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe cfg.package} ${if cfg.deviceName != "" then "--device \"${cfg.deviceName}\"" else ""} ${if cfg.watch then "--watch" else ""} ${configFile}";
        Restart = "always";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
