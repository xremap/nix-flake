{ self, ... }:
{ testers, procps }:
testers.runNixOSTest {
  name = "Test wlroots-hyprland with home manager";

  skipTypeCheck = true;

  nodes.machine =
    { ... }:
    {
      imports = [
        (import ../demo-nixos-configurations/wlroots-hyprland.nix { inherit self; })
        ../common/no-network-in-tests.nix
        {
          home-manager.users.alice.services.xremap.config.keymap = [
            {
              application.only = "kitty";
              remap."9" = "0";
            }
          ];
        }
      ];
    };

  testScript = /* python */ ''
    start_all()
    machine.wait_for_unit("default.target", timeout=10)
    # machine.send_chars("Hyprland\n")
    machine.wait_until_succeeds("${procps}/bin/pgrep xremap", timeout=10)
    machine.wait_for_unit("xremap.service", "alice", timeout=10)

    # Start kitty
    machine.sleep(1)
    machine.send_key('meta_l-ctrl-k')
    machine.wait_until_succeeds("${procps}/bin/pgrep kitty", timeout=10)

    machine.sleep(5) # Wait for it to fully start. This wait is janky.
    output_file = "/tmp/xremap-output"
    machine.send_chars(f"echo -n '9' > {output_file}\n")
    machine.sleep(2)
    output = machine.execute(f"cat {output_file}")[1]
    expected_output = "0"

    assert output == expected_output, f"Not the expected symbol. Expected: '{expected_output}' found: '{output}'!"

  '';
}
