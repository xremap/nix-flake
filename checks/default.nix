{ self, pkgs, lib, ... }:
let
  checks = [
    ./xremap-no-features-root-test.nix
  ];
in
lib.pipe checks
  [
    (map (checkFile:
      {
        name = builtins.toString checkFile;
        value = pkgs.testers.runNixOSTest (import checkFile { inherit self; });
      }
    ))
    builtins.listToAttrs
  ]

