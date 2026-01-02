/**
  Tests setting the debug value and that it properly merges with hand-set variables.
*/
{ self, ... }:
{ testers }:
testers.runNixOSTest {
  name = "xremap-debug";
  nodes.machine1 =
    { ... }:
    {
      services.getty.autologinUser = "root";
      imports = [
        self.nixosModules.default
        ../common/no-network-in-tests.nix
        {
          services.xremap = {
            enable = true;
            config.keymap = [
              {
                name = "Other remap";
                remap = {
                  "z" = "q";
                };
              }
            ];
          };
        }
        { services.xremap.debug = true; }
        { systemd.services.xremap.serviceConfig.Environment = [ "FOO=BAR" ]; } # This should get merged.
      ];
    };

  testScript =
    # python
    ''
      start_all()
      machine.wait_for_unit("xremap.service")

      # technically one should use dbus api but eh.
      __, stdout = machine.execute("systemctl show --property Environment xremap")
      parsed_stdout = stdout.removeprefix("Environment=").rstrip().split(" ")
      # A bit flaky since we're parsing strings. Dbus API better approach. To be fixed if becomes a problem.
      assert "RUST_LOG=debug" in parsed_stdout, "Looks like RUST_LOG did not get passed"
      assert "FOO=BAR" in parsed_stdout, "Looks like a custom variable did not get merged"
    '';
}
