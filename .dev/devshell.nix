/**
  Configures development shell for the subflake.
*/
{
  config,
  lib,
  self',
  ...
}:
{
  default = {
    commands = [
      {
        help = "Run the CI formatter locally";
        package = config.treefmt.build.wrapper;
      }
    ]
    ++ (lib.pipe self'.apps [
      builtins.attrNames
      (map (app: {
        name = app;
        command = "(cd $PRJ_ROOT && nix run .#${app})";
        help = "Run this flake's app '${app}'";
        category = "flake apps";
      }))
    ]);
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
        help = "Check formatting, fail on changes";
        name = "fmt";
        command = /* bash */ ''
          ${lib.getExe config.treefmt.build.wrapper} --ci
        '';
      }
      {
        help = "Build xremap with features one by one";
        name = "build-all-features";
        command = /* bash */ ''
          features=( "gnome" "hypr" "x11" "wlroots" "kde" "cosmic" )

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
