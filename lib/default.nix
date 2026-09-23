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

  # Maps options to upstream Cargo features
  # Except `withSway`, deprecated upstream
  withFeatures = {
    withGnome = "gnome";
    withX11 = "x11";
    withHypr = "hypr";
    withKDE = "kde";
    withWlroots = "wlroots";
    withNiri = "niri";
    withCosmic = "cosmic";
    withPantheon = "pantheon";
    withSocket = "socket";
  };
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
    withPantheon = mkEnableOption "support Pantheon";
    withSocket = mkEnableOption "the socket client (for driving xremap from another process; can't be auto-selected)";
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
        let
          # Since `v0.15.13` (xremap PR #1004), upstream compiles every enabled feature into one
          # binary and picks the desktop client at runtime (auto-detected, or via `--desktop`).
          # Previously compile time checks validated exclusivity of flags, now
          # multiple are okay.
          features =
            lib.pipe withFeatures [
              (lib.filterAttrs (name: _: cfg.${name}))
              builtins.attrValues
            ]
            ++ lib.optional (cfg.withSway && !cfg.withWlroots) (
              lib.warn "Consider using withWlroots as recommended by upstream" "wlroots"
            );
          uniqueFeatures = lib.unique features;
          hasDesktopArg = lib.any (arg: arg == "--desktop" || lib.hasPrefix "--desktop=" arg) cfg.extraArgs;
          selectedPackage =
            if uniqueFeatures == [ ] then
              selfPkgs'.xremap
            else if lib.length uniqueFeatures == 1 then
              selfPkgs'."xremap-${lib.head uniqueFeatures}"
            else
              # More than one backend requested: fall back to xremap-full rather than building a
              # custom combination of exactly the requested features. Simpler, but means this compiles
              # every backend's deps, not just the ones enabled -- see the note in docs/HOWTO.md.
              #
              # xremap-full also compiles in KDE even when withKDE itself isn't set. Deliberately
              # not blocked here the way `withKDE` is below: with the default `--desktop auto`,
              # a KDE client that can't connect (e.g. running as root) is just skipped by
              # auto-detection in favor of the next compiled-in client, not a hard failure -- so
              # this doesn't get the same root restriction as explicitly requesting `withKDE`.
              selfPkgs'.xremap-full;
        in
        assert
          (
            cfg.withKDE
            -> (
              # TODO: if some other place would need checking that it's a home manager module. If so -- add a "_hm" parameter to the module.
              !(builtins.hasAttr "serviceMode" cfg) || (cfg.serviceMode == "user") # First check that "serviceMode" is present in the config. If not -- it's home manager module.
            )
          )
          || throw "Upstream does not support running withKDE as root";

        if cfg.withSocket && !hasDesktopArg then
          lib.warn "services.xremap.withSocket is enabled, but '--desktop' is not specified in extraArgs. Upstream cannot auto-detect the socket client; consider adding extraArgs = [ \"--desktop\" \"socket\" ];" selectedPackage
        else
          selectedPackage;
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
