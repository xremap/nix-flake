/**
  A demo of `xremap` running in X11.

  To run the demo:

  1. Run the test interactively
  2. Run `start_all()`
  3. Launch standard terminal and kitty
  4. Hit `alt-a` and `alt-9` to see changed bindings
*/
{ self, ... }:
{ testers }:
testers.runNixOSTest {
  name = "x11-system-mode";
  nodes.machine =
    { pkgs, ... }:
    {
      # X11 setup
      services.xserver = {
        enable = true;
        desktopManager.xfce.enable = true;
      };
      services.displayManager.autoLogin = {
        enable = true;
        user = "alice";
      };

      # Run a single one-shot service that allows root's services to access user's X session
      systemd.user.services.set-xhost = {
        description = "Run a one-shot command upon user login";
        path = [ pkgs.xorg.xhost ];
        wantedBy = [ "graphical-session.target" ];
        script = "xhost +SI:localuser:root";
        environment.DISPLAY = ":0.0";
      };

      systemd.user.services.restart-xremap-upon-login = {
        description = "Restart system wide xremap to make sure it picks up user's X session";
        path = [];
        wantedBy = [ "graphical-session.target" ];
        # `wrappers` so that it's the proper sudo
        script = "/run/wrappers/bin/sudo systemctl restart xremap";
        environment.DISPLAY = ":0.0";
      };

      environment.systemPackages = [
        pkgs.kitty
      ];
      imports = [
        ../common/common-setup.nix
        self.nixosModules.default
      ];

      services.xremap = {
        enable = true;
        withX11 = true;
        serviceMode = "system";
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
