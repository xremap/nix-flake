/**
  A catch-all test of home manager module implementation.

  in its current form this test only tests the "`xremap` can start and is kinda
  configured as expected" fact
*/
{ self, ... }:
{ testers }:
testers.runNixOSTest {

  name = "home-manager general check";
  nodes.machine =
    { lib, ... }:
    {
      imports = [
        ../common/common-setup.nix
        ../common/setup-uinput.nix
        ../common/no-network-in-tests.nix
        self.inputs.home-manager.nixosModules.home-manager
      ];

      home-manager.users.alice = {
        imports = [
          self.homeManagerModules.default
          { services.xremap.enable = true; }
          { services.xremap.deviceNames = [ "/dev/input/event0" ]; }
          # Enable debug
          { services.xremap.debug = true; }
          # This test just checks some basic things about `xremap` service
          # Not using graphical option, setting `xremap` to start with default.target
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
      machine.wait_until_tty_matches("1", r"alice@machine", 30)
      machine.wait_for_unit("xremap.service", "alice", 30)

      # technically one should use dbus api but eh.
      _, stdout = machine.systemctl("show --property=Environment xremap", "alice")
      parsed_stdout = stdout.removeprefix("Environment=").rstrip().split(" ")
      # A bit flaky since we're parsing strings. Dbus API better approach. To be fixed if becomes a problem.
      assert "RUST_LOG=debug" in parsed_stdout, "Looks like RUST_LOG did not get passed"
      assert "FOO=BAR" in parsed_stdout, "Looks like a custom variable did not get merged"
    '';
}
