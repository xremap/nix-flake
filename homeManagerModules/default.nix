{ localFlake, withSystem }:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.xremap;
  localLib = localFlake.localLib { inherit pkgs lib cfg; };
  inherit (localLib) mkExecStart configFile;
  inherit (lib) mkIf mkMerge optionalAttrs;
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
      Service = mkMerge [
        {
          Type = "simple";
          ExecStart = mkExecStart configFile;
          Restart = "always";
        }
        (optionalAttrs cfg.debug { Environment = [ "RUST_LOG=debug" ]; })
      ];
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
