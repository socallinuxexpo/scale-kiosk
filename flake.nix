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
      ];
      flake = { ... }: {
        packages = {
          # We only ever want to build for arm64, even when the host is
          # x86_64-linux, maybe we should show a trace when building in order to be
          # more informative?
          x86_64-linux = self.packages.aarch64-linux;
          aarch64-linux = {
            pi-kiosk-sdImage = (self.nixosConfigurations.pi-kiosk.extendModules {
              modules = [ "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix" ];
            }).config.system.build.sdImage;
          };
        };
        nixosConfigurations = {
          pi-kiosk = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
              "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"
              nixos-hardware.nixosModules.raspberry-pi-4
              ./configuration.nix
              ./base.nix
            ];
          };
        };
      };
    };
}

