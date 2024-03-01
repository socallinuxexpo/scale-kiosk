{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixos-shell.url = "github:Mic92/nixos-shell";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs = { self, nixpkgs, nixos-hardware, nixos-shell, flake-parts }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./flake-modules/binfmt-sdk.nix
      ];
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      perSystem = { system, pkgs, ... }: {
        apps.vm = let
          vmScript = (nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              ./configuration.nix
              ./base.nix
            ];
          }).config.system.build.vm;
        in {
          type = "app";
          program = builtins.toPath (pkgs.writeShellScript "stateless-kiosk-vm" ''
            TMPDIR=$(mktemp -d)
            function cleanup {
              rm -rf "$TMPDIR"
            }
            trap cleanup 0
            cd $TMPDIR
            ${pkgs.lib.getExe vmScript}
          '');
        };
      };
      flake = { ... }: {
        # We only ever want to build for arm64, even when the host is
        # x86_64-linux, maybe we should show a trace when building in order to be
        # more informative?
        packages.x86_64-linux.pi-kiosk-sdImage = self.packages.aarch64-linux.pi-kiosk-sdImage;
        packages.aarch64-linux.pi-kiosk-sdImage = (self.nixosConfigurations.pi-kiosk.extendModules {
          modules = [
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            {
              disabledModules = [ "profiles/base.nix" ];
            }
          ];
        }).config.system.build.sdImage;
        nixosConfigurations = {
          pi-kiosk = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
              nixos-hardware.nixosModules.raspberry-pi-4
              ./configuration.nix
              ./base.nix
            ];
          };
        };
      };
    };
}

