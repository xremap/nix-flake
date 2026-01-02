/**
  This snippet disables networking in tests, speeding them up.
*/
{
  virtualisation.qemu.networkingOptions = [ ];
  systemd.network.wait-online.enable = false;
  networking.useDHCP = false;
  networking.interfaces = { };
  systemd.services.network-setup.enable = false;
}
