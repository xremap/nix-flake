/**
  Checks that --deviceNames (plural) option creates a working xremap configuration.

  Starts the VM and checks the ExecStart value of the systemd unit.
*/
{ self, ... }:
{
  name = "xremap-single-device";
  nodes.machine1 =
    { config, pkgs, ... }:
    {
      services.getty.autologinUser = "root";
      imports = [
        self.nixosModules.default
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
        {
          services.xremap.deviceNames = [
            # Always present in qemu
            "event0"
            "event1"
          ];
        }
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

      assert stdout.count("--device") == 2, "--device should be present expected amount of times"
    '';
}
