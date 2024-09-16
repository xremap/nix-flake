{ self, ... }:
{
  name = "xremap-no-features-root-test";
  nodes.machine1 =
    { config, ... }:
    {
      services.getty.autologinUser = "root";
      imports = [
        self.nixosModules.default
        {
          services.xremap.config.keymap = [
            {
              name = "First remap";
              remap = {
                "9" = "0";
              };
            }
          ];
        }
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
    };

  # This test makes sure that both remaps are applied
  testScript =
    # python
    ''
      output_file = "/tmp/xremap-output"
      start_all()
      machine.wait_for_unit("xremap.service")
      machine.sleep(2)

      # Wait for login -- this test runs against tty
      machine.wait_until_tty_matches("1", "login: ")

      machine.send_chars(f"echo -n 'z' > {output_file}\n")
      machine.sleep(2)

      output = machine.execute(f"cat {output_file}")[1]

      assert output == "q", "Not the expected symbol!"

      machine.send_chars(f"echo -n '9' > {output_file}\n")
      machine.sleep(2)

      output = machine.execute(f"cat {output_file}")[1]

      assert output == "0", "Not the expected symbol!"

    '';
}
