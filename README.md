> [!IMPORTANT]
> Recent commit set `services.xremap.enable` to `false` by default so that it
> matches other modules. Make sure to enable the service
> (`services.xremap.enable = true;`)

# What this is

This is a [Nix flake](https://nixos.wiki/wiki/Flakes) that installs and configures [xremap](https://github.com/k0kubun/xremap).

Flake allows running xremap as a system-wide service and as a user service (controlled by `services.xremap.serviceMode` option).

Flake implements xremap features that allow specifying per-application remapping. Following combinations are tested:

| Scenario | No features | KDE | Gnome | X11 | Wlroots | Niri | Cosmic |
| - | - | - | - | - | - | - | - |
| System | :heavy_check_mark: | :heavy_multiplication_x: | :heavy_multiplication_x: | :heavy_check_mark: | :heavy_multiplication_x: | :question: | :question: |
| User   | :heavy_check_mark: | :heavy_check_mark: |  :heavy_check_mark:       | :question: | :heavy_check_mark:           | :heavy_check_mark: | :question: |

:heavy_check_mark: – tested, works
:heavy_multiplication_x: – not implemented
:question: – not tested

# How to use

TL;DR:

1. Import one of this flake's modules (`xremap-flake.nixosModules.default` or `xremap-flake.homeManagerModules.default`)
2. (optional) configure xremap for your DE (`services.xremap.withWlroots`/`withX11`/etc., see [HOWTO](./docs/HOWTO.md))
3. Configure xremap binds in `services.xremap.config`

See [HOWTO](./docs/HOWTO.md) for more information and sample configs.

# Development

The nix flake comes with a few VM presets that can be used to test some of the combinations. To run a specific VM:

```shell
nix run '.#nixosConfigurations.hyprland-user-dev.config.system.build.vm
```

where `hyprland-user-dev` is the name of the `nixosConfiguration` you want to launch
