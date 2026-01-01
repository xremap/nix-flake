/**
  A demo of `xremap` running in Niri.

  To run the demo:

  1. Run the test interactively
  2. Run `start_all()`
  3. Launch standard terminal and kitty (`ctrl-t`/`ctrl-shift-t`)
  4. Hit `alt-a` and `alt-9` to see changed bindings
*/

{ self, ... }:
{ testers, ... }:
testers.runNixOSTest {
  name = "xremap-niri-user";
  nodes.machine1 =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      # Niri setup
      environment.etc = {
        "niri/config.kdl".text = ''
          binds {
              Ctrl+T cooldown-ms=500 { spawn "${lib.getExe pkgs.foot}"; }
              Ctrl+Shift+T cooldown-ms=500 { spawn "${lib.getExe pkgs.kitty}"; }
          }
        '';
      };

      virtualisation.graphics = true;
      # Niri needs very specific graphical options to run in QEMU:
      # https://discourse.nixos.org/t/nixos-build-vm-niri/61155
      virtualisation.qemu.options = [
        "-device virtio-vga-gl"
        "-display gtk,gl=on"
      ];
      hardware.graphics.enable = true;

      imports = [
        ../common/common-setup.nix
        ../common/setup-uinput.nix
        self.nixosModules.default
      ];

      programs.niri.enable = true;

      services.greetd = {
        enable = true;
        settings = rec {
          # Effectively auto-login
          default_session = initial_session;
          initial_session = {
            command = "${config.programs.niri.package}/bin/niri-session";
            user = "alice";
          };
        };
      };

      # TODO: make this part of the module
      systemd.user.services.xremap.after = [ "niri.service" ];

      services.xremap = {
        enable = true;
        withNiri = true;
        serviceMode = "user";
        userName = "alice";
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

  testScript =
    # python
    ''
      start_all()
      # Wait until login
      machine.wait_until_tty_matches("1", r"alice@machine1")
      machine.send_chars("niri --session\n")
      machine.sleep(5)

      # start foot
      machine.send_key("ctrl-t")
      machine.sleep(2)
      # Forcing start of xremap to propagate NIRI_SOCKET path
      machine.send_chars("systemctl --user start xremap\n")
      machine.sleep(2)
      machine.screenshot("test")
      machine.wait_for_unit("xremap", "alice")

      # Test the binding
      # Try z in foot (current terminal)
      output_file = "/tmp/foot_output"
      machine.send_chars(f"echo 'z' > {output_file}\n")
      output = machine.execute(f"cat {output_file}")[1]
      assert output == "z", "Key should not be remapped"

      # Launch kitty, check that the symbol is remapped
      machine.send_key("ctrl-shift-t")
      machine.sleep(2)
      output_file = "/tmp/kitty_output"
      machine.send_chars(f"echo 'z' > {output_file}\n")
      output = machine.execute(f"cat {output_file}")[1]
      assert output == "q", "Key should be remapped"
    '';
}
