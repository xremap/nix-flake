{ localFlake }:
{
  pkgs,
  lib,
  cfg,
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  selfPkgs' = localFlake.packages.${system};

  settingsFormat = pkgs.formats.yaml { };

  inherit (lib.types) nullOr listOf nonEmptyStr;
  inherit (lib) pipe singleton showWarnings;
in
{
  commonOptions = with lib; {
    withSway = mkEnableOption "support for Sway (consider switching to wlroots)";
    withGnome = mkEnableOption "support for Gnome";
    withX11 = mkEnableOption "support for X11";
    withHypr = mkEnableOption "support for post-wlroots Hyprland";
    withWlroots = mkEnableOption "support for wlroots-based compositors (Sway, old Hyprland, etc.)";
    withKDE = mkEnableOption "support KDE-Plasma Wayland";
    withNiri = mkEnableOption "support Niri";
    withCosmic = mkEnableOption "support Cosmic";
    enable = mkOption {
      type = types.bool;
      #  This warning should be emitted <=> default value is used.
      default = lib.warn ''
        xremap module is imported but services.xremap.enable is false. As of a flake commit 1448d83, it is false by default.

        This warning is emitted when the module default value (false) is used.

        If you want to enable xremap, set `services.xremap.enable` to `true` in your config.

        If you want to keep the module import but disable the service and suppress the warning, set `services.xremap.enable` to `false`.
      '' false;
      description = "Enable xremap service";
    };
    package = mkOption {
      type = types.package;
      default =
        assert
          (
            cfg.withKDE
            -> (
              # TODO: if some other place would need checking that it's a home manager module. If so -- add a "_hm" parameter to the module.
              !(builtins.hasAttr "serviceMode" cfg) || (cfg.serviceMode == "user") # First check that "serviceMode" is present in the config. If not -- it's home manager module.
            )
          )
          || throw "Upstream does not support running withKDE as root";

        # Check that 0 or 1 features are enabled, since upstream throws an error otherwise
        assert
          (
            lib.lists.count (x: x) (
              builtins.attrValues {
                inherit (cfg)
                  withSway
                  withGnome
                  withX11
                  withHypr
                  withWlroots
                  withKDE
                  withNiri
                  withCosmic
                  ;
              }
            ) <= 1
          )
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
          selfPkgs'.xremap-hypr
        else if cfg.withKDE then
          selfPkgs'.xremap-kde
        else if cfg.withNiri then
          selfPkgs'.xremap-niri
        else if cfg.withCosmic then
          selfPkgs'.xremap-cosmic
        else
          selfPkgs'.xremap;
    };
    config = mkOption {
      type = types.submodule { freeformType = settingsFormat.type; };
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
    deviceNames = mkOption {
      type = nullOr (listOf nonEmptyStr);
      default = null;
      description = "List of devices to remap.";
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

  configFile =
    assert
      ((cfg.yamlConfig == "" && cfg.config != { }) || (cfg.yamlConfig != "" && cfg.config == { }))
      || throw "Xremap's config needs to be specified either in .yamlConfig or in .config";
    if cfg.yamlConfig == "" then
      settingsFormat.generate "config.yml" cfg.config
    else
      pkgs.writeTextFile {
        name = "xremap-config.yml";
        text = cfg.yamlConfig;
      };

  mkExecStart =
    configFile:
    let
      mkDeviceString = x: "--device '${x}'";
    in
    builtins.concatStringsSep " " (
      lib.flatten (
        lib.lists.singleton "${lib.getExe cfg.package}"
        ++ (
          /*
            Logic to handle --device parameter.

            Originally only "deviceName" (singular) was an option. Upstream implemented multiple devices, e.g.:
            https://github.com/xremap/xremap/issues/44

            Option "deviceNames" (plural) is implemented to allow passing a list of devices to remap.

            Legacy parameter wins by default to prevent surprises, but emits a warning.
          */
          if cfg.deviceName != "" then
            pipe cfg.deviceName [
              mkDeviceString
              singleton
              (showWarnings [
                "'deviceName' option is deprecated in favor of 'deviceNames'. Current value will continue working but please replace it with 'deviceNames'."
              ])
            ]
          else if cfg.deviceNames != null then
            map mkDeviceString cfg.deviceNames
          else
            [ ]
        )
        ++ lib.optional cfg.watch "--watch"
        ++ lib.optional cfg.mouse "--mouse"
        ++ cfg.extraArgs
        ++ lib.lists.singleton configFile
      )
    );
}
