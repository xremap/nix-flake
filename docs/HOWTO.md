# Installation

The installation depends on whether you are using [NixOS](#nixos) or [home-manager](#non-nixos-and-home-manager).

Regardless of the chosen approach, the installation consists of:

1. Importing this flake's module
2. Configuring xremap

Note that flakes are required. If there is a demand for non-flake-based modules -- please feel free to submit an issue.

## NixOS

There are two main ways of running xremap -- as a system service or as a user service. Not all combinations of mode x desktop environment are supported:

| Scenario | No features | KDE | Gnome | X11 | Wlroots |
| - | - | - | - | - | - |
| System | :heavy_check_mark: | :heavy_multiplication_x: | :heavy_multiplication_x: | :heavy_check_mark: | :heavy_multiplication_x: |
| User   | :heavy_check_mark: | :heavy_check_mark: |  :heavy_check_mark:       | :question: | :heavy_check_mark:           |

For all examples in this section you can copy the code into a random `flake.nix` on your machine and run it in a VM as `nix run <path_to_flake>#nixosConfigurations.nixos.config.system.build.vm`.

<details>
 <summary>
  
  ## System module, no desktop environment
  </summary>

  A very simple configuration that globally maps CapsLock to Escape and Ctrl+U to Page Up can look like this:
  
  ```nix
  # flake.nix
  {
    inputs.xremap-flake.url = "github:xremap/nix-flake";
    outputs = inputs@{ nixpkgs, ... }: {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          inputs.xremap-flake.nixosModules.default
          /* This is effectively an inline module */
          {
            users.users.root.password = "hunter2";
            system.stateVersion = "24.05";
  
            # Modmap for single key rebinds
            services.xremap.config.modmap = [
              {
                name = "Global";
                remap = { "CapsLock" = "Esc"; }; # globally remap CapsLock to Esc
              }
            ];
  
            # Keymap for key combo rebinds
            services.xremap.config.keymap = [
              {
                name = "Example ctrl-u > pageup rebind";
                remap = { "C-u" = "PAGEUP"; };
                # NOTE: no application-specific remaps work without features (see configuration)
              }
            ];
          }
        ];
      };
    };
  }
  ```
</details>


<details>
  <summary>
   
   ## User module
   </summary>

  ```nix
  # flake.nix
  {
    inputs.xremap-flake.url = "github:xremap/nix-flake";
    outputs = inputs@{ nixpkgs, ... }: {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          inputs.xremap-flake.nixosModules.default
          /* This is effectively an inline module */
          {
            users.users.root.password = "hunter2";
            users.users.alice = {
              password = "hunter2";
              isNormalUser = true;
            };
  
            system.stateVersion = "24.05";
            # This configures the service to only run for a specific user
            services.xremap = {
              /* NOTE: since this sample configuration does not have any DE, xremap needs to be started manually by systemctl --user start xremap */
              serviceMode = "user";
              userName = "alice";
            };
            # Modmap for single key rebinds
            services.xremap.config.modmap = [
              {
                name = "Global";
                remap = { "CapsLock" = "Esc"; }; # globally remap CapsLock to Esc
              }
            ];
  
            # Keymap for key combo rebinds
            services.xremap.config.keymap = [
              {
                name = "Example ctrl-u > pageup rebind";
                remap = { "C-u" = "PAGEUP"; };
              }
            ];
          }
        ];
      };
    };
  }
  ```
</details>

<details>
  <summary>
   
  ## Systemwide example with X feature for application-specific remaps 
  </summary>

  ```nix
  # flake.nix
  {
    inputs.xremap-flake.url = "github:xremap/nix-flake";
    outputs = inputs@{ nixpkgs, ... }: {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          inputs.xremap-flake.nixosModules.default
          /* This is effectively an inline module */
          (
            { pkgs, ... }:
            {
              users.users.root.password = "hunter2";
              users.users.alice = {
                password = "hunter2";
                isNormalUser = true;
                extraGroups = [ "wheel" ];
              };
  
              system.stateVersion = "24.05";
  
              services.xserver = {
                enable = true;
                desktopManager.xfce.enable = true; # xfce is just an example
              };
              environment.systemPackages = [ pkgs.kitty ];
  
              /* Run a single one-shot service that allows root's services to access user's X session */
              systemd.user.services.set-xhost = {
                description = "Run a one-shot command upon user login";
                path = [ pkgs.xorg.xhost ];
                wantedBy = [ "default.target" ];
                script = "xhost +SI:localuser:root";
                environment.DISPLAY = ":0.0"; # NOTE: This is hardcoded for this flake
              };
  
              /* Enable X11 feature support */
              services.xremap.withX11 = true;
              # Modmap for single key rebinds
              services.xremap.config.modmap = [
                {
                  name = "Global";
                  remap = { "CapsLock" = "Esc"; }; # globally remap CapsLock to Esc
                }
              ];
  
              # Keymap for key combo rebinds
              services.xremap.config.keymap = [
                {
                  name = "Example ctrl-u > pageup rebind, only for specific application";
                  remap = { "C-u" = "PAGEUP"; };
                  application.only = [ "kitty" ];
                }
              ];
            }
          )
        ];
      };
    };
  }
  ```
</details>

## Non-NixOS and home-manager

Since on non-NixOS configurations, the environment outside the user cannot be controlled (e.g. home-manager cannot add the user to `uinput`), additional steps may be needed. See [upstream](https://github.com/k0kubun/xremap) for more information.

TODO

# Example configurations

TODO

# Xremap service configuration

There are three categories of options:

1. `enabled` option; true by default for mostly historic reasons.
2. Options that enable package features (support for X/Wayland) or service configuration.

    Feature flags are:

    * `withWlroots`, `bool` – whether to enable wlroots-based compositor support (Sway, Hyprland, etc.)
    * `withGnome`, `bool` – whether to enable Gnome support
    * `withX11`, `bool` – whether to enable X11 support
    * `withKDE`, `bool` – whether to enable KDE wayland support

    All of them are false by default, which means no application-specific remaps work as xremap does not know which application is being used.

    * `serviceMode`, `str` – whether to run as user ("`user`") or system ("`system`", default)
    * `userName`, `str` – Name of user logging into graphical session (not set by default)
    * `userId`, `int` – user under which IPC socket runs (1000 by default)
    * `watch`, `bool` – whether to watch for new devices (false by default)
    * `mouse`, `bool` – whether to watch for mice (false by default)
    * `deviceNames`, `list of str`, – list of devices to monitor (empty by default)
    * `extraArgs`, `list of str`, – list of arguments to provide for xremap (empty by default)
    * `package` – which package for xremap to use. Useful if you want to somehow override the flake-provided package.
    * `debug` – enables debug logging for xremap (off by default)

3. Options that define xremap's config. See [upstream](https://github.com/k0kubun/xremap) for more options.

    They are defined in either `services.xremap.config` as a Nix attrset or in `services.xremap.yamlConfig` as raw YAML text.


# Troubleshooting

## Environment variables

### systemd service

The xremap.service will only have access to environment variables defined
through the `Environment=` and `EnvironmentFile=` entries in the service file.
Moreover, other environment variables may be made available to the service by
using `systemctl [--user] set-environment VARIABLE=VALUE`.

To expose `home.sessionVariables` to the service, the following may be done:

```nix
{lib, pkgs, ...}:
{
  # This will make every variable to have a `Environment=VARIABLE=VALUE` entry.
  systemd.user.services.xremap.Service = {
    Environment = lib.mapAttrsToList (n: v: "${n}=\"${builtins.toString v}\"") config.home.sessionVariables;
  };
  # This will make a single `EnvironmentFile` entry, but implies the build of
  # derivation.
  systemd.user.services.xremap.Service = {
    EnvironmentFile = builtins.toString (
      pkgs.writeText "xremap-session-vars-as-env-d" (
        builtins.concatStringsSep "\n" (
          lib.mapAttrsToList (n: v: "${n}=\"${builtins.toString v}\"") config.home.sessionVariables
        )
      )
    );
  };
}
```

#### Session variables being overwritten by `/etc/profile` family of files on a shell

This happens because the session variables are set before the `/etc/profile`
files are sourced, which happens only the shell is spawned.

It can be fixed with the following if guard (following example uses Bash in a
posix compliant manner, so it may be used on posix compliant shells, but needs
adaptation for non compliant ones like fish):

```nix
{config, lib, ...}: {
  programs.bash.initExtra = lib.mkOrder 99 ''
    if [ -z "$__HM_SESS_VARS_SOURCED" ]; then
      . ${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh
    fi
  '';
}
```

Now, the session variables will be sourced after the ones from `/etc/profile`.

### Calling the binary directly as a non-root user

For xremap to have access to the user environment the following may be done:

1. If using home-manager for managing the xsession:
	```nix
	{pkgs, ...}:
	{
	  xsession.initExtra = ''
	    ${lib.getExe pkgs.xremap} <path-to-config-file>
	  '';
	}
	```
	This exposes `home.sessionVariables` to xremap, since the `xsession` file
	sources the `xprofile` file, which sources the file with the session
	variables.
1. If not using home-manager, DE/WM specific solutions may be used, that is, a
   way to launch xremap together with. Here are some non exhaustive solutions:
   1. dwm: add `<binary> <config-file> &` to the autostart.sh script, if using
	  the [autostart patch](https://dwm.suckless.org/patches/autostart/).
   1. Hyprland: hyprctl use `hyprctl exec <binary>`.

### Cannot launch applications

If there is a binding to launch an application that looks like this:

```nix
{
  name = "apps";
  remap.alt-f.launch = [ "pavucontrol" ];
}
```

But nothing happens, and you see this in the logs:

```
Jan 01 19:30:46 nix xremap[595413]: [2024-01-01T16:30:46Z DEBUG xremap::action_dispatcher] Running command: ["pavucontrol"]
Jan 01 19:30:46 nix xremap[650912]: [2024-01-01T16:30:46Z ERROR xremap::action_dispatcher] Error running command: Os { code: 2, kind: NotFound, message: "No such file or directory" }
```

This happens because of a discrepancy in `$PATH` variable between your environment and xremap service.

Two approaches to solve this:
1. Use binds to something like `${lib.getExe pkgs.pavucontrol}`
2. (not applicable to all DEs) use the bind to call DE-specific utility, e.g. `hyprctl exec <binary>`. This way whatever UI customizations are present on the DE level will get propagated to launched binary.

## (specific to X11) xremap starts but app-specific shortcuts are not working

If you are using X11 and have enabled `withX11`, but the application-specific keybinds do not work, check the logs (`journalctl -u xremap`).

Should the logs contain:

```
Failed to connect to X11: X11 setup failed: 'Authorization required, but no authorization protocol specified
```

You would need to run `xhost +SI:localuser:root`. One approach to do this is described in [this example config](#systemwide-example-with-x-feature-for-application-specific-remaps).

## Xremap service is not started automatically

Happens if `serviceMode == "user"` or when using home-manager module; typically because `graphical-session.target` is not launched automatically.

If you are using a desktop environment (Gnome, KDE, something wlroots-based, etc.) – make sure that the target is started.

If you intend to use xremap without a DE, change `systemd.user.services.xremap.wantedBy` to some target that starts after you log in or manually start `systemctl --user start xremap`

## Xremap does not restart on config change

Not (yet?) implemented, see #49.

## Something else

Feel free to submit an [issue](https://github.com/xremap/nix-flake/issues) or reach out to the main contributor of the repo via any other means.
