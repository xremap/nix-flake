# What this is

This is a [Nix flake](https://nixos.wiki/wiki/Flakes) that installs and configures [xremap](https://github.com/k0kubun/xremap).

Flake allows running xremap as a system-wide service and as a user service (controlled by `services.xremap.serviceMode` option).

Flake implements xremap features that allow specifying per-application remapping. Following combinations are tested:

| Scenario | No features | Sway | Gnome | X11 | Hyprland |
| - | - | - | - | - | - |
| System | :heavy_check_mark: | :heavy_check_mark:`*` | :heavy_multiplication_x: | :heavy_check_mark: | :heavy_multiplication_x:`**` |
| User   | :heavy_check_mark: | :heavy_check_mark:    | :heavy_check_mark:       | :question: | :heavy_check_mark:           |

:heavy_check_mark: – tested, works
:heavy_multiplication_x: – not implemented
:question: – not tested

`*`: Sway system mode requires restarting the system service after user logs in for the service to pick up the Sway socket.

`**`: Hyprland feature can be enabled, but the service cannot find a socket

# How to use
## On NixOS

1. Add following to your `flake.nix`:

    ```nix
    {
        inputs.xremap-flake.url = "github:xremap/nix-flake";
    }
    ```

2. Import the `xremap-flake.nixosModules.default` module.
3. Configure the [module options](#Configuration)

<details>
  <summary>Sample config</summary>
  
  Assuming flake-managed machine with hostname `nixos`:
  
  ```nix
  # flake.nix
  {
    inputs.xremap-flake.url = "github:xremap/nix-flake";
    outputs = inputs@{ ... }: {
      nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          inputs.xremap-flake.nixosModules.default
          {
            services.xremap = {
              userName = "alice";  # run as a systemd service in alice
              serviceMode = "user";  # run xremap as user
              config = {
                modmap = [
                  {
                      name = "Global";
                      remap = { "CapsLock" = "Esc"; };  # globally remap CapsLock to Esc
                  }
                ];
              };
            };
          }
        ];
        # < the rest of configuration >
      };
    };
  }
  ```
</details>

## Using home-manager on non-NixOS system
1. Add following to your `flake.nix`:

    ```nix
    {
        inputs.xremap-flake.url = "github:xremap/nix-flake";
    }
    ```

2. Import the `xremap-flake.homeManagerModules.default` module.
3. Set the [module options](#Configuration) without the user-related settings. This will create a systemd user service with xremap.
4. [Configure xremap to run without sudo](https://github.com/k0kubun/xremap#usage) by adding your user to `input` group and (optionally) adding the udev rule.

## Any other configuration

Alternatively, one of the flake packages (see `nix flake show github:xremap/nix-flake`) can be used with `nix run` to launch xremap with the corresponding feature.

# Configuration

Following `services.xremap` options are exposed:

* `serviceMode` – whether to run as user or system
* `withSway` – whether to enable Sway support
* `withGnome` – whether to enable Gnome support
* `withHypr` – whether to enable Hyprland support
* `withX11` – whether to enable X11 support
* `package` – which package for xremap to use
* `config` – configuration for xremap defined as Nix attribute set. See [original repo](https://github.com/k0kubun/xremap) for examples.

    Alternatively raw config in YAML format can be specified in `.yamlConfig` option.

* `userId` – user under which Sway IPC socket runs
* `userName` – Name of user logging into graphical session
* `deviceName` – the name of the device to be used. To find out the name, you can check `/proc/bus/input/devices`
* `watch` – whether to watch for new devices

See examples in `nixosConfigurations` inside flake.nix.

# Developemnt

The nix flake comes with a few VM presets that can be used to test some of the combinations. To run a specific VM:

```shell
nix run '.#nixosConfigurations.hyprland-user-dev.config.system.build.vm
```

where `hyprland-user-dev` is the name of the `nixosConfiguration` you want to launch
