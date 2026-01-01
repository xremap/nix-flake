{ modulesPath, ... }:
{
  virtualisation = {
    graphics = true;
    qemu.options = [
      "-device virtio-vga-gl"
      "-display gtk,gl=on"
    ];
    memorySize = 2048;
  };

  hardware.graphics.enable = true;

  imports = [
    (modulesPath + "/virtualisation/qemu-vm.nix") # adds '`virtualisation`' options
  ];
}
