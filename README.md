# What this is

This is a [Nix flake](https://nixos.wiki/wiki/Flakes) that installs and configures [xremap](https://github.com/k0kubun/xremap).

Flake allows running xremap as a system-wide service and as a user service (controlled by `services.xremap.serviceMode` option).

Flake implements xremap features that allow specifying per-application remapping. Following combinations are tested:

| Scenario | No features | Sway | Gnome | X11 |
| - | - | - | - | - |
| System | :heavy_check_mark: | :heavy_check_mark:    | :heavy_multiplication_x: | :question: |
| User   | :heavy_check_mark: | :heavy_check_mark:`*` | :heavy_check_mark:       | :question: |

:heavy_check_mark: – tested, works
:heavy_multiplication_x: – not implemented
:question: – not tested

`*`: Sway system mode requires restarting the system service after user logs in for the service to pick up the Sway socket.

# How to use
## As a module

1. Add following to your `flake.nix`:

    ```nix
    {
        inputs.xremap-flake.url = "github:VTimofeenko/xremap?dir=nix-flake";
    }
    ```

2. Import the `xremap-flake.nixosModules.defalut` module.
3. Configure the [module options](#Configuration)

Alternatively, flake application can be `nix run` to launch xremap without features.

# Configuration

Following `services.xremap` options are exposed:

* `serviceMode` – whether to run as user or system
* `withSway` – whether to enable Sway support
* `withGnome` – whether to enable Gnome support
* `withX11` – whether to enable X11 support
* `package` – which package for xremap to use
* `config` – configuration for xremap defined as Nix attribute set. See [original repo](https://github.com/k0kubun/xremap) for examples.
* `userId` – user under which Sway IPC socket runs
* `userName` – Name of user logging into graphical session
* `deviceName` – the name of the device to be used. To find out the name, you can check `/proc/bus/input/devices`
* `watch` – whether to watch for new devices
