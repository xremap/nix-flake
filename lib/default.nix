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
    withKDE = mkEnableOption "support KDE-Plasma Wayland";
    package = mkOption {
      type = types.package;
      default =
        assert (cfg.withKDE -> (
          # TODO: if some other place would need checking that it's a home manager module. If so -- add a "_hm" parameter to the module.
          !(builtins.hasAttr "serviceMode" cfg) || (cfg.serviceMode == "user")  # First check that "serviceMode" is present in the config. If not -- it's home manager module.
        )) || throw "Upstream does not support running withKDE as root";

        # Check that 0 or 1 features are enabled, since upstream throws an error otherwise
        assert (lib.lists.count (x: x == true) (builtins.attrValues { inherit (cfg) withSway withGnome withX11 withHypr withWlroots withKDE; }) <= 1)
          || throw "Xremap cannot be built with more than one feature. Check that no more than 1 with* feature is enabled";

        if cfg.withWlroots then
          selfPkgs'.xremap-wlroots
        else if cfg.withSway then
          lib.warn "Consider using withWlroots as recommended by upstream" selfPkgs'.xremap-sway
        else if cfg.withGnome then
          selfPkgs'.xremap-gnome
        else if cfg.withX11 then
          selfPkgs'.xremap-x11
        else if cfg.withHypr then
          lib.warn "Consider using withWlroots as recommended by upstream" selfPkgs'.xremap-hypr
        else if cfg.withKDE then
          selfPkgs'.xremap-kde
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
      default = [ ];
      example = [ "--completions zsh" ];
      description = "Extra arguments for xremap";
    };
    debug = mkEnableOption "run xremap with RUST_LOG=debug in case upstream needs logs";
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
          lib.optional cfg.mouse "--mouse"
          ++
          cfg.extraArgs
          ++
          lib.lists.singleton configFile
        )
      );
}
