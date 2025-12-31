/**
  A demo of `xremap` running in KDE.

  Uses NixOS module and runs in `user` mode.

  Note that this demo is fairly large space-wise and KDE is not the fastest DE
  when it comes to starting/stopping disposable environments.

  To run the demo:

  1. Run the test interactively
  2. Run `start_all()`
  3. Log in as `alice` (password below)
  4. Start kitty and foot
  5. Hit `alt-a` and `alt-9` to see changed bindings
*/
{ self, ... }:
{ testers }:
testers.runNixOSTest {
  name = "kde-nixos-module-usermode";

  nodes.machine =
    { pkgs, ... }:
    {
      # KDE setup
      # Source: https://wiki.nixos.org/wiki/KDE
      services.xserver.enable = true;
      services.displayManager = {
        # optional
        sddm.enable = true;
        sddm.wayland.enable = true;
      };
      services.desktopManager.plasma6.enable = true;

      environment.systemPackages = [
        pkgs.kitty
        pkgs.foot
      ];

      # Imports
      imports = [
        ../common/common-setup.nix
        self.nixosModules.default
      ];

      services.xremap = {
        enable = true;
        withKDE = true;
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
