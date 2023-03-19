# NOTE: modulesPath and imports are taken from nixpkgs#59219
{ modulesPath, pkgs, lib, ... }: {
  imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];
  users.users.root.password = "root";
  users.users.alice = {
    password = "hunter2";
    isNormalUser = true;
  };
  system.stateVersion = "22.11";
  virtualisation.graphics = true;
  documentation.enable = false;
  virtualisation.forwardPorts = [
    # SSH
    { from = "host"; host.port = 64022; guest.port = 22; }
  ];
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  virtualisation.qemu.options = [
    # NOTE: Looks like Wayland in QEMU absolutely needs these
    "-device virtio-vga-gl"
    "-display gtk,gl=on"
    # To pass a keyboard directly to the VM
    # "-device usb-host,hostbus=3,hostaddr=2"
  ];
  environment.sessionVariables = rec {
    # NOTE: Looks like Wayland in QEMU absolutely needs these
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    XCURSOR_SIZE = "24";
  };
  environment.systemPackages = with pkgs; [ vim kitty foot ];
}

