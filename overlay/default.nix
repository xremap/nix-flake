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

  packageWithFeature =
    feature:
    craneLib.buildPackage (
      commonArgs
      // {
        inherit cargoArtifacts;
        cargoExtraArgs = "--locked${if (feature != null) then " --features ${feature}" else ""}";
        # cargoBuildOptions = (x: x ++ pkgs.lib.optional (feature != null) "--features ${feature}");
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
      (packageWithFeature "wlroots");
in
rec {
  # No features
  default = xremap;
  xremap = packageWithFeature null;
  xremap-wlroots = packageWithFeature "wlroots";
  xremap-sway = mkUpstreamDeprecatedNote "sway";
  xremap-gnome = packageWithFeature "gnome";
  xremap-x11 = packageWithFeature "x11";
  xremap-hypr = packageWithFeature "hypr";
  xremap-kde = packageWithFeature "kde";
  xremap-niri = packageWithFeature "niri";
  xremap-cosmic = packageWithFeature "cosmic";
}
