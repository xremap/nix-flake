/**
  A demo of `xremap` running in Niri.

  To run the demo:

  1. Launch standard terminal and kitty (`ctrl-t`/`ctrl-shift-t`)
  2. Hit `alt-a` and `alt-9` to see changed bindings
*/
{ self, ... }:
{
  pkgs,
  lib,
  config,
  ...
}:
{
  # Niri setup
  environment.etc = {
    "niri/config.kdl".text = ''
      binds {
          Ctrl+T cooldown-ms=500 { spawn "${lib.getExe pkgs.foot}"; }
          Ctrl+Shift+T cooldown-ms=500 { spawn "${lib.getExe pkgs.kitty}"; }
      }
    '';
  };

  imports = [
    ../common/common-setup.nix
    ../common/setup-uinput.nix
    ../common/qemu-graphics.nix
    self.nixosModules.default
  ];

  programs.niri.enable = true;

  services.greetd = {
    enable = true;
    settings = rec {
      # Effectively auto-login
      default_session = initial_session;
      initial_session = {
        command = "${config.programs.niri.package}/bin/niri-session";
        user = "alice";
      };
    };
  };

  # TODO: make this part of the module
  systemd.user.services.xremap.after = [ "niri.service" ];

  services.xremap = {
    enable = true;
    withNiri = true;
    serviceMode = "user";
    userName = "alice";
    config = {
      keymap = [
        {
          name = "Remap 'alt-a' to 'b' in kitty";
          application = {
            "only" = "kitty";
          };
          remap = {
            "ALT-a" = "b";
          };
        }
        {
          name = "Remap 'alt-9' to '0' everywhere";
          remap = {
            "ALT-9" = "0";
          };
        }
      ];
    };
  };
}
