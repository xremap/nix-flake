/**
  A demo of `xremap` running in hyprland.

  Uses home manager module.

  To run the demo:

  1. Run the test interactively
  2. Run `start_all()`
  3. Once auto-login happens, execute `Hyprland` to start hyprland
  4. Start kitty and foot (see hyprland config below for bindings)
  5. Hit `alt-a` and `alt-9` to see changed bindings
*/
{ self, ... }:
{ testers }:
testers.runNixOSTest {
  name = "Wlroots-hyprland-demo";

  nodes.machine =
    { lib, pkgs, ... }:
    {
      # Hyprland-specific
      hardware.graphics.enable = true;
      home-manager.users.alice = {
        home.stateVersion = "25.11";
        wayland.windowManager.hyprland.enable = true;
        wayland.windowManager.hyprland.extraConfig = ''
          bind = SUPER CTRL, k, exec, ${lib.getExe pkgs.kitty}
          bind = SUPER CTRL, f, exec, ${lib.getExe pkgs.foot}
        '';
      };

      # Imports
      imports = [
        ../common/common-setup.nix
        ../common/setup-uinput.nix
        self.inputs.home-manager.nixosModules.home-manager
      ];

      # `xremap` config is here
      home-manager.users.alice = {
        imports = [ self.homeManagerModules.default ];
        services.xremap = {
          enable = true;
          withWlroots = true;
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
    };

  # TODO: implement
  testScript = /* python */ ''
    machine.wait_for_unit("default.target")

  '';
}
