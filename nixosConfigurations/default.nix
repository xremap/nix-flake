{ localFlake, inputs }:
let
  system = "x86_64-linux";
  pkgs = inputs.nixpkgs;
  commonModules = [
    localFlake.nixosModules.default
    ./vm-config.nix
    {
      services.xremap = {
        userName = "alice";
        config = {
          keymap = [
            {
              name = "Test remap a>b in kitty";
              application = {
                "only" = "kitty";
              };
              remap = {
                "a" = "b";
              };
            }
            {
              name = "Test remap 9>0 everywhere";
              remap = {
                "9" = "0";
              };
            }
          ];
        };
      };
    }
  ];
  mkDevSystem =
    { hostName, customModules }:
    pkgs.lib.nixosSystem {
      inherit system;
      modules =
        commonModules
        ++ customModules
        ++ [
          {
            networking = {
              inherit hostName;
            };
          }
        ];
    };
in
{
  # gnome-system = abort "Tested ad-hoc";
  gnome-user =
    mkDevSystem {
      hostName = "gnome-user";
      customModules = [ ./gnome-common.nix ];
    }
    // {
      _comment = "Enable the xremap Gnome extension manually.";
    };
  testAssertFail = mkDevSystem {
    hostName = "testAssertFail";
    customModules = [ { services.xremap.config = pkgs.lib.mkForce { }; } ];
  };
  testMultipleWithFail =
    mkDevSystem {
      hostName = "testMultipleWithFail";
      customModules = [
        {
          services.xremap = {
            withWlroots = true;
            withX11 = true;
          };
        }
      ];
    }
    // {
      _comment = "This VM should not run successfully; shows an error message about multiple with*";
    };
}
