# Function that produces common things to reuse across modules
{ pkgs, lib, cfg, localFlake }:
let
  packages' = localFlake.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  configFile = pkgs.writeTextFile {
    name = "xremap-config.yml";
    text =
      assert ((cfg.yamlConfig == "" && cfg.config != { }) || (cfg.yamlConfig != "" && cfg.config == { }));
      if cfg.yamlConfig == "" then pkgs.lib.generators.toYAML { } cfg.config else cfg.yamlConfig;
  };
  commonOptions = with lib; {
    withSway = mkEnableOption "support for Sway";
    withGnome = mkEnableOption "support for Gnome";
    withX11 = mkEnableOption "support for X11";
    withHypr = mkEnableOption "support for Hyprland";
    package = mkOption {
      type = types.package;
      default =
        if cfg.withSway then
          packages'.xremap-sway
        else if cfg.withGnome then
          packages'.xremap-gnome
        else if cfg.withX11 then
          packages'.xremap-x11
        else if cfg.withHypr then
          packages'.xremap-hypr
        else
          packages'.xremap
      ;
    };
    config = mkOption {
      type = types.attrs;
      description = "Xremap configuration. See xremap repo for examples. Cannot be used together with .yamlConfig";
      default = { };
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
    yamlConfig = mkOption {
      type = types.str;
      default = "";
      description = ''
        The text of yaml config file for xremap. See xremap repo for examples. Cannot be used together with .config.
      '';
      example = ''
        modmap:
          - name: Except Chrome
            application:
              not: Google-chrome
            remap:
              CapsLock: Esc
        keymap:
          - name: Emacs binding
            application:
              only: Slack
            remap:
              C-b: left
              C-f: right
              C-p: up
              C-n: down
      '';
    };
    deviceName = mkOption {
      type = types.str;
      default = "";
      description = "Device name which xremap will remap. If not specified - xremap will remap all devices.";
    };
    watch = mkEnableOption "running xremap watching new devices";
  };
}
