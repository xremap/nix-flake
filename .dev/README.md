This is a development subflake of xremap nix flake.

It hosts:

- Formatter that uses `treefmt`
- Demo nix apps that show how `xremap` service runs in various environments. They
  are implemented as NixOS virtual machines. Their configs are in `./demo-nixos-configurations/`
- Module tests in `./checks/`

To run the full test suite, run `nix develop .dev#ci` and execute
`run-integration-tests`. There may be some evaluation warnings, but they are
expected.

To bump the `xremap` input to a new upstream release, run `bump-xremap
<version>` (e.g. `bump-xremap v0.15.14`) from the default devshell. It updates
`flake.nix`'s `ref=`, then relocks both the top-level `flake.lock` and
`.dev/flake.lock` (the latter's `parent` input mirrors the top-level xremap
pin, so it needs relocking too). Edits are staged.
