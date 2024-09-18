/**
  A catch-all test of home manager module implementation.

  NOTE: in its current form this test only tests the "xremap can start and is kinda configured as expected" fact
*/
{ self, ... }:
{
  name = "xremap-single-device";
  nodes.machine1 =
    { config, lib, ... }:
    {
      services.getty.autologinUser = "alice";
      users.users.alice = {
        isNormalUser = true;
        password = "hunter2";
        extraGroups = [ "input" ];
      };
      imports = [ self.inputs.home-manager.nixosModules.home-manager ];

      hardware.uinput.enable = true;
      services.udev = {
        # NOTE: Xremap requires the following:
        # https://github.com/xremap/xremap?tab=readme-ov-file#running-xremap-without-sudo
        extraRules = ''
          KERNEL=="uinput", GROUP="input", TAG+="uaccess"
        '';
      };

      home-manager.users.alice = {
        imports = [
          self.homeManagerModules.default
          { services.xremap.enable = true; }
          { services.xremap.deviceNames = [ "/dev/input/event0" ]; }
          # Enable debug
          { services.xremap.debug = true; }
          # NOTE: This test just checks some basic things about xremap service
          # Not using graphical option, setting xremap to start with default.target
          { systemd.user.services.xremap.Unit.PartOf = lib.mkForce [ "default.target" ]; }
          { systemd.user.services.xremap.Unit.After = lib.mkForce [ "default.target" ]; }
          { systemd.user.services.xremap.Install.WantedBy = lib.mkForce [ "default.target" ]; }
          # Try merging FOO=BAR to env
          { systemd.user.services.xremap.Service.Environment = [ "FOO=BAR" ]; }
          # Try setting an env var
          {
            services.xremap.config.keymap = [
              {
                name = "Other remap";
                remap = {
                  "z" = "q";
                };
              }
            ];
          }
        ];
        home.stateVersion = "24.05";
      };
    };

  testScript =
    # python
    ''
      start_all()
      # Wait until login
      machine.wait_until_tty_matches("1", r"alice@machine1")
      machine.wait_for_unit("xremap.service", "alice")

      # technically one should use dbus api but eh.
      _, stdout = machine.systemctl("show --property=Environment xremap", "alice")
      parsed_stdout = stdout.removeprefix("Environment=").rstrip().split(" ")
      # A bit flaky since we're parsing strings. Dbus API better approach. To be fixed if becomes a problem.
      assert "RUST_LOG=debug" in parsed_stdout, "Looks like RUST_LOG did not get passed"
      assert "FOO=BAR" in parsed_stdout, "Looks like a custom variable did not get merged"
    '';
}
