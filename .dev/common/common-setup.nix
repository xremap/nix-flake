/**
  Common module to be used by all demos and checks.
*/
{
  services.getty.autologinUser = "alice";
  users.users.alice = {
    isNormalUser = true;
    password = "hunter2";
    extraGroups = [
      "input"
      "wheel"
    ];
  };
  # Fonts will likely be necessary for UI stuff
  fonts.enableDefaultPackages = true;

  security.sudo = {
    wheelNeedsPassword = false;
    execWheelOnly = true;
  };
}
