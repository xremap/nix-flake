{ self, ... }:
{ testers, procps }:
testers.runNixOSTest {
  name = "Test xremap running in X11 in system mode";

  skipTypeCheck = true;

  nodes.machine =
    { ... }:
    {
      imports = [
        (import ../demo-nixos-configurations/x11-system.nix { inherit self; })
        ../common/no-network-in-tests.nix
        {
          services.xremap.config.keymap = [
            {
              application.only = "kitty";
              remap."9" = "0";
            }
          ];
        }
      ];
    };

  testScript = /* python */ ''
    machine.wait_for_x(timeout=10)
    # machine.send_chars("Hyprland\n")
    machine.wait_until_succeeds("${procps}/bin/pgrep xremap", timeout=10)
    machine.wait_for_unit("xremap.service", timeout=10)
    machine.wait_for_unit("graphical-session.target", "alice", timeout=10)

    # Start kitty
    machine.sleep(1)
    machine.execute("kitty >&2 &")
    machine.wait_for_window("root@machine")
    # machine.wait_until_succeeds("${procps}/bin/pgrep kitty", timeout=10)

    machine.sleep(2) # Wait for it to fully start
    output_file = "/tmp/xremap-output"
    machine.send_chars(f"echo -n '9' > {output_file}\n")
    machine.sleep(2)
    output = machine.execute(f"cat {output_file}")[1]
    expected_output = "0"

    assert output == expected_output, f"Not the expected symbol. Expected: '{expected_output}' found: '{output}'!"

  '';
}
