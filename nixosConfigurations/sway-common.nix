{ pkgs, ... }:

{
  environment.etc."sway/config.d/test".text = ''
    bindsym k exec ${pkgs.kitty}/bin/kitty
    bindsym f exec ${pkgs.foot}/bin/foot
  '';
  services.xremap = {
    withSway = true;
  };
}
