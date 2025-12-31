/**
  This module can be used to emulate `uinput` configuration outside the tested
  module.
*/
{
  hardware.uinput.enable = true;
  services.udev = {
    # `xremap` requires this:
    # https://github.com/xremap/xremap?tab=readme-ov-file#running-xremap-without-sudo
    extraRules = ''
      KERNEL=="uinput", GROUP="input", TAG+="uaccess"
    '';
  };
}
