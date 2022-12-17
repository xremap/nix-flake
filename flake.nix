{
  description = "Flake that configures Xremap, a key remapper for Linux";

  inputs = {
    # Nixpkgs will be pinned to unstable to get the latest Rust
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Utils for building Rust stuff
    naersk.url = "github:nmattia/naersk/master";
    # The Rust source for xremap
    xremap = {
      url = "github:k0kubun/xremap?ref=v0.7.11";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, naersk, xremap }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    rec
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          naersk-lib = pkgs.callPackage naersk { };
        in
        {
          default = (import ./overlay xremap naersk-lib pkgs { }).xremap-unwrapped;
        }
      );
      apps = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          naersk-lib = pkgs.callPackage naersk { };
          package = (import ./overlay xremap naersk-lib pkgs { }).xremap-unwrapped;
        in
        {
          default = {
            type = "app";
            program = "${package}/bin/xremap";
          };
        }
      );
      devShells = forAllSystems
        (system:
          let
            pkgs = nixpkgsFor.${system};
          in
          {
            default =
              with pkgs; mkShell {
                buildInputs = [ cargo rustc rustfmt rustPackages.clippy ];
                RUST_SRC_PATH = rustPlatform.rustLibSrc;
              };
          }
        );

      # See comments in the module
      nixosModules.default = import ./modules xremap naersk;
    };
}
