# Overlay file that contains the definition of building a package
{ xremap, naersk-lib, pkgs }:
let
  packageWithFeature = feature: naersk-lib.buildPackage {
    root = xremap;
    cargoBuildOptions = (x: x ++ pkgs.lib.optional (feature != null) "--features ${feature}");
    # The following two options are for introspection to be able to see if sway/gnome were actually pulled in
    # To see that - visually inspect the deps directory inside result/target/ and check for swayipc/zbus
    # See cargo.toml for feature-specific deps
    copyTarget = true;
    compressTarget = false;
    meta.mainProgram = "xremap";
  };
in
rec {
  # No features
  default = xremap;
  xremap = packageWithFeature null;
  xremap-wlroots = packageWithFeature "wlroots";
  xremap-sway = packageWithFeature "sway";
  xremap-gnome = packageWithFeature "gnome";
  xremap-x11 = packageWithFeature "x11";
  xremap-hypr = packageWithFeature "hypr";
}
