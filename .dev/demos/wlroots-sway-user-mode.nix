/**
  A demo of `xremap` running on sway.

  Uses NixOS module and runs in `user` mode.

  To run the demo:

  1. Run the test interactively
  2. Run `start_all()`
  3. Once auto-login happens, execute `sway` to start sway
  4. Start kitty and foot (see sway config below for bindings)
  5. Hit `alt-a` and `alt-9` to see changed bindings
*/
{ self, ... }:
{ testers }:
testers.runNixOSTest {
  name = "wlroots-sway-nixos-module-usermode";
  nodes.machine =
    { pkgs, ... }:
    {

      # Imports
      imports = [
        ../common/common-setup.nix
        # `xremap` config is here
        self.nixosModules.default
      ];

      programs.sway.enable = true;

      environment.etc."sway/config.d/test".text = ''
        bindsym super+ctrl+k exec ${pkgs.kitty}/bin/kitty
        bindsym super+ctrl+f exec ${pkgs.foot}/bin/foot
      '';

      services.xremap = {
        enable = true;
        withWlroots = true;
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
    };

  # TODO: implement
  testScript = /* python */ ''
    machine.wait_for_unit("default.target")

  '';
}
