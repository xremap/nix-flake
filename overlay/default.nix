# Overlay file that contains the definition of building a package
{
  xremap,
  craneLib,
  pkgs,
  ...
}:
let
  inherit (pkgs) lib;
  commonArgs = {
    src = xremap;
    strictDeps = true;

    buildInputs = [
      # Add additional build inputs here
    ];

    # Additional environment variables can be set directly
    # MY_CUSTOM_VAR = "some value";
  };
  cargoArtifacts = craneLib.buildDepsOnly commonArgs;

  # `features` is a list of xremap Cargo feature names
  # An empty list builds xremap with no desktop-client integration.
  packageWithFeatures =
    features:
    craneLib.buildPackage (
      commonArgs
      // {
        inherit cargoArtifacts;
        cargoExtraArgs = "--locked${
          lib.optionalString (features != [ ]) " --features ${lib.concatStringsSep "," features}"
        }";
        # The following two options are for introspection to be able to see if sway/gnome were actually pulled in
        # To see that - visually inspect the deps directory inside result/target/ and check for swayipc/zbus
        # See cargo.toml for feature-specific deps
        # copyTarget = true;
        # compressTarget = false;
        meta.mainProgram = "xremap";
      }
    );

  mkUpstreamDeprecatedNote =
    feature:
    lib.warn
      ''
        Xremap: upstream has deprecated feature '${feature}' in favor of 'wlroots'.

        The package will be built with 'wlroots' but in future release of the Nix flake this will turn into an error.''
      (packageWithFeatures [ "wlroots" ]);
in
rec {
  # No features
  default = xremap;
  xremap = packageWithFeatures [ ];
  xremap-wlroots = packageWithFeatures [ "wlroots" ];
  xremap-sway = mkUpstreamDeprecatedNote "sway";
  xremap-gnome = packageWithFeatures [ "gnome" ];
  xremap-x11 = packageWithFeatures [ "x11" ];
  xremap-hypr = packageWithFeatures [ "hypr" ];
  xremap-kde = packageWithFeatures [ "kde" ];
  xremap-niri = packageWithFeatures [ "niri" ];
  xremap-cosmic = packageWithFeatures [ "cosmic" ];
  xremap-pantheon = packageWithFeatures [ "pantheon" ];
  xremap-socket = packageWithFeatures [ "socket" ];
  # All desktop-client backends compiled in, matching upstream's `full` Cargo feature.
  # Selection between them happens at runtime via `--desktop` (or auto-detection).
  # Also what the module falls back to when more than one `with*` flag is enabled,
  # since it's a strict superset of every other package here.
  xremap-full = packageWithFeatures [ "full" ];
}
