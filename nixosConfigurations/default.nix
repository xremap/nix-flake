{ localFlake, inputs }:
let
  system = "x86_64-linux";
  pkgs = inputs.nixpkgs;
  commonModules = [
    localFlake.nixosModules.default
    ./vm-config.nix
    {
      services.xremap = {
        userName = "alice";
        config = {
          keymap = [
            {
              name = "Test remap a>b in kitty";
              application = {
                "only" = "kitty";
              };
              remap = {
                "a" = "b";
              };
            }
            {
              name = "Test remap 9>0 everywhere";
              remap = {
                "9" = "0";
              };
            }
          ];
        };
      };
    }
  ];
  mkDevSystem = { hostName, customModules }: pkgs.lib.nixosSystem {
    inherit system;
    modules = commonModules ++ customModules ++ [{
      networking = { inherit hostName; };
    }];
  };
in
{
  # no-features-system = abort "Tested ad-hoc";
  # no-features-user = abort "Tested ad-hoc";
  sway-system = mkDevSystem
    {
      hostName = "sway-system";
      customModules = [
        # Autologin
        { services.getty.autologinUser = "alice"; }
        # Sway
        {
          programs.sway.enable = true;
        }
        ./sway-common.nix
      ];
    } // { _comment = "After auto-login, run 'sway' and 'sleep 1 && systemctl restart xremap'. Sleep is needed to prevent xremap from capturing extra input."; };
  sway-wlroots-system = mkDevSystem
    {
      hostName = "sway-wlroots-system";
      customModules = [
        # Autologin
        { services.getty.autologinUser = "alice"; }
        # Sway
        {
          programs.sway.enable = true;
        }
        ./sway-common.nix
        {
          services.xremap = {
            withSway = pkgs.lib.mkForce false;
            withWlroots = true;
          };
        }
      ];
    } // { _comment = "After auto-login, run 'sway' and 'sleep 1 && systemctl restart xremap'. Sleep is needed to prevent xremap from capturing extra input."; };
  # sway-user = abort "Tested ad-hoc";
  # gnome-system = abort "Tested ad-hoc";
  gnome-user = mkDevSystem
    {
      hostName = "gnome-user";
      customModules = [
        ./gnome-common.nix
      ];
    } // { _comment = "Enable the xremap Gnome extension manually."; };
  x11-system = mkDevSystem
    {
      hostName = "x11-system";
      customModules = [
        # Autologin
        { services.getty.autologinUser = "alice"; }
        {
          services.xserver = {
            autorun = false;
            displayManager.startx.enable = true;
            enable = true;
            windowManager.openbox.enable = true;
          };
        }
      ];
    } // { _comment = "Run startx after autologin."; };
  # x11-user = abort "Tested ad-hoc";
  # hypr-system = abort "Not implemented";
  hypr-user = mkDevSystem
    {
      hostName = "hypr-user";
      customModules = [
        # Autologin
        { services.getty.autologinUser = "alice"; }
        inputs.hyprland.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
        { home-manager = { users.alice = { ... }: { imports = [ inputs.hyprland.homeManagerModules.default ]; }; }; }
        { services.xremap = { withHypr = true; serviceMode = "user"; }; }
        ./hypr-common.nix
      ];
    } // { _comment = "Login with the user's password and run 'Hyprland' in tty. Launch Kitty and test."; };
  hypr-wlroots-user = mkDevSystem
    {
      hostName = "hypr-wlroots-user";
      customModules = [
        # Autologin
        { services.getty.autologinUser = "alice"; }
        inputs.hyprland.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
        { home-manager = { users.alice = { ... }: { imports = [ inputs.hyprland.homeManagerModules.default ]; }; }; }
        { services.xremap = { withWlroots = true; serviceMode = "user"; }; }
        ./hypr-common.nix
      ];
    } // { _comment = "Login with the user's password and run 'Hyprland' in tty. Launch Kitty and test."; };
  testAssertFail = mkDevSystem {
    hostName = "testAssertFail";
    customModules = [{ services.xremap.config = pkgs.lib.mkForce { }; }];
  };
  kde-wayland-user = mkDevSystem {
    hostName = "kde-wayland-user";
    customModules = [
      { services.xremap = { withKDE = true; serviceMode = "user"; }; }
      ./kde-common.nix
    ];
  };
}
