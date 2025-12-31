/**
  Effectively only checks that the `deviceName` (singular) parameter can still be used.

  Starts the VM and checks the `ExecStart` value of the Systemd unit.
*/
{ self, ... }:
{ testers }:
testers.runNixOSTest {
  name = "xremap-single-device";
  nodes.machine1 =
    { ... }:
    {
      services.getty.autologinUser = "root";
      imports = [
        self.nixosModules.default
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
        { services.xremap.deviceName = "event0"; }
      ];
    };

  testScript =
    # python
    ''
      start_all()
      machine.wait_for_unit("xremap.service")

      machine.sleep(2)
      status, _ = machine.execute("systemctl status xremap")
      assert status == 0, "Looks like xremap failed after starting."

      __, stdout = machine.execute("systemctl show xremap | grep ExecStart=")
      assert stdout.count("--device") == 1, "--device should be present once and only once in the systemd ExecStart"
    '';
}
