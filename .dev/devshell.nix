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
      {
        help = "Bump the xremap input to a new tag (e.g. bump-xremap v0.15.14) and refresh both locks";
        name = "bump-xremap";
        command = /* bash */ ''
          set -euo pipefail

          version="''${1:-}"
          if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "Usage: bump-xremap <version>, e.g. bump-xremap v0.15.14" >&2
            exit 1
          fi

          # Just in case, redeclare PRJ_ROOT
          PRJ_ROOT="$(git rev-parse --show-toplevel)"

          sed -i -E "s|(url = \"github:k0kubun/xremap\?ref=)v[0-9]+\.[0-9]+\.[0-9]+(\")|\1''${version}\2|" "$PRJ_ROOT/flake.nix"

          (cd "$PRJ_ROOT" && nix flake lock --update-input xremap)
          (cd "$PRJ_ROOT/.dev" && nix flake lock --update-input parent)

          echo
          echo "Bumped xremap to $version. Review the diff, then commit (signed), e.g.:"
          echo "  git add flake.nix flake.lock .dev/flake.lock"
          echo "  (or)"
          echo "  git add -u"
          echo "  git commit -S -m \"chore: bump xremap input to ''${version#v}\""
        '';
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
        help = "Build xremap with features one by one, plus the no-features and full packages";
        name = "build-all-features";
        command =
          let
            # Dynamically build features from `self'`
            # Alternative is parsing nix flake show, but that would need `jq`, an extra dep.
            singleFeatures = lib.pipe self'.packages [
              builtins.attrNames
              (builtins.filter (
                name: name != "xremap-full" && name != "xremap-sway" && lib.hasPrefix "xremap-" name
              ))
              (map (lib.removePrefix "xremap-"))
            ];
          in
          /* bash */ ''
            set -euo pipefail

            features=( ${lib.concatMapStringsSep " " (f: ''"${f}"'') singleFeatures} )

            echo "Building xremap"
            nix build .#xremap
            echo "Build successful"

            for feature in "''${features[@]}"; do
            echo "Building feature $feature"
            nix build .#xremap-''${feature}
            echo "Build successful"
            done

            echo "Building xremap-full"
            nix build .#xremap-full
            echo "Build successful"
          '';
      }
      {
        help = "Run all integration tests";
        name = "run-integration-tests";
        command = /* bash */ ''
          pushd $(git rev-parse --show-toplevel)
          for i in $(nix flake show --json .dev 2>/dev/null| jq -r '.checks."x86_64-linux" | keys | .[]' | grep -v 'treefmt'); do
            echo "Running test $i"
            nix build ".dev#checks.x86_64-linux.$i"
            echo "Done"
          done

          popd
        '';
      }
    ];
  };
}
