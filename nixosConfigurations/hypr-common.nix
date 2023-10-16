# Hyprland config for testing xremap
{ lib, pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
  };
  hardware.opengl.enable = true;
  home-manager =
    {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.alice = { ... }: {
        home.stateVersion = "23.05";
        wayland.windowManager.hyprland =
          {
            enable = true;
            # Makes xremap auto-start with hyprland
            systemdIntegration = true;
            extraConfig = ''
              bind = SUPER CTRL, k, exec, ${lib.getExe pkgs.kitty}
              bind = SUPER CTRL, f, exec, ${lib.getExe pkgs.foot}
            '';
          };
      };
    };
}
