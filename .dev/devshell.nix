/**
  Configures development shell for the subflake.
*/
{ ... }:
{
  defalult = {
    commands = [ ];
    /**
      If needed, this block can be restored to add rust building stuff
      ```
      packages = builtins.attrValues {
        inherit (pkgs) cargo rustc rustfmt;
        inherit (pkgs.rustPackages) clippy;
      };
      ```
    */
  };
  ci = {
    commands = [
      {
        help = "Build xremap with features one by one";
        name = "build-all-features";
        command = /* bash */ ''
          set -euo pipefail

          features=( "gnome" "hypr" "sway" "x11" "wlroots" "kde" "cosmic" )

          for feature in "''${features[@]}"; do
          echo "Building feature $feature"
          nix build .#xremap-''${feature}
          echo "Build successful"
          done
        '';
      }
    ];
  };
}
