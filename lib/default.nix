{ localFlake }:
{ pkgs, lib, cfg }:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  selfPkgs' = localFlake.packages.${system};
in
{
  commonOptions = with lib; {
    withSway = mkEnableOption "support for Sway (consider switching to wlroots)";
    withGnome = mkEnableOption "support for Gnome";
    withX11 = mkEnableOption "support for X11";
    withHypr = mkEnableOption "support for Hyprland (consider switching to wlroots)";
    withWlroots = mkEnableOption "support for wlroots-based compositors (Sway, Hyprland, etc.)";
    package = mkOption {
      type = types.package;
      default =
        if cfg.withWlroots then
          selfPkgs'.xremap-wlroots
        else if cfg.withSway then
          selfPkgs'.xremap-sway
        else if cfg.withGnome then
          selfPkgs'.xremap-gnome
        else if cfg.withX11 then
          selfPkgs'.xremap-x11
        else if cfg.withHypr then
          selfPkgs'.xremap-hypr
        else
          selfPkgs'.xremap
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
    mouse = mkEnableOption "watching mice by default";
    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "--completions zsh" ];
      description = "Extra arguments for xremap";
    };
  };
  configFile = pkgs.writeTextFile {
    name = "xremap-config.yml";
    text =
      assert ((cfg.yamlConfig == "" && cfg.config != { }) || (cfg.yamlConfig != "" && cfg.config == { })) || throw "Xremap's config needs to be specified either in .yamlConfig or in .config";
      if cfg.yamlConfig == "" then pkgs.lib.generators.toYAML { } cfg.config else cfg.yamlConfig;
  };
  mkExecStart = configFile:
    builtins.concatStringsSep " "
      (lib.flatten
        (
          lib.lists.singleton "${lib.getExe cfg.package}"
          ++
          lib.optional (cfg.deviceName != "") "--device \"${cfg.deviceName}\""
          ++
          lib.optional cfg.watch "--watch"
          ++
          lib.optional cfg.mouse "--watch"
          ++
          lib.lists.singleton configFile
          ++
          cfg.extraArgs
        )
      );
}
