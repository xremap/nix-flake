{ localFlake, withSystem }:
{ config, pkgs, lib, ... }:
let
  cfg = config.services.xremap;
  localLib = localFlake.localLib { inherit pkgs lib cfg; };
  inherit (localLib) mkExecStart configFile;
  inherit (lib) mkIf optionalString;
in
{
  options.services.xremap = localLib.commonOptions;
  config = mkIf cfg.enable {
    systemd.user.services.xremap = {
      Unit = {
        Description = "xremap service";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = mkExecStart configFile;
        Restart = "always";
        Environment = optionalString cfg.debug "RUST_LOG=debug";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
