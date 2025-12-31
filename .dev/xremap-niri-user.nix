/**
  Tests that this flake can be used with Niri.

  NOTE: this check does _NOT_ run automatically. Looks like NixOS testing
  framework runs without the graphics that are required to test this properly.
  See comments for `virtualisation.qemu.options` below.
*/

{ self, ... }:
{
  name = "xremap-niri-user";
  nodes.machine1 =
    {
      pkgs,
      lib,
      ...
    }:
    {
      services.getty.autologinUser = "alice";
      users.users.alice = {
        isNormalUser = true;
        password = "hunter2";
        extraGroups = [ "input" ];
      };

      environment.systemPackages = [
        self.packages.${pkgs.system}.xremap-niri
      ];

      environment.etc = {
        "niri/config.kdl".text = ''
          binds {
              Ctrl+T cooldown-ms=500 { spawn "${lib.getExe pkgs.foot}"; }
              Ctrl+Shift+T cooldown-ms=500 { spawn "${lib.getExe pkgs.kitty}"; }
          }
        '';
      };

      virtualisation.graphics = true;
      # Niri needs very specific graphical options to run in qemu:
      # https://discourse.nixos.org/t/nixos-build-vm-niri/61155
      virtualisation.qemu.options = [
        "-device virtio-vga-gl"
        "-display gtk,gl=on"
      ];
      hardware.graphics.enable = true;

      hardware.uinput.enable = true;
      services.udev.extraRules = ''
        KERNEL=="uinput", GROUP="input", TAG+="uaccess"
      '';

      programs.niri.enable = true;

      imports = [
        self.nixosModules.default
        { services.xremap.enable = true; }
        { services.xremap.withNiri = true; }
        {
          services.xremap.userName = "alice";
          services.xremap.serviceMode = "user";
        }
        {
          services.xremap.config.keymap = [
            {
              name = "Example rebind, only for specific application";
              remap = {
                "z" = "q";
              };
              application.only = [ "kitty" ];
            }
          ];
        }
      ];

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
