{ self, inputs, ... }:
{
  flake = { pkgs, ... }: {
    apps.x86_64-linux.binfmt-sdk-nixos-shell = {
      type = "app";
      program = builtins.toPath (inputs.nixpkgs.legacyPackages.x86_64-linux.writeShellScript "run-binfmt-sdk-nixos-shell" ''
        rm nixos.qcow2 || true
        export NIX_CONFIG="experimental-features = nix-command flakes"
        export PATH=$PATH:${inputs.nixpkgs.legacyPackages.x86_64-linux.nixUnstable}/bin
        ${inputs.nixos-shell.packages.x86_64-linux.nixos-shell}/bin/nixos-shell --flake ${self}#binfmt-sdk-nixos-shell
      '');
    };
    nixosConfigurations.binfmt-sdk-nixos-shell = inputs.nixpkgs.lib.makeOverridable inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.nixos-shell.nixosModules.nixos-shell
        ({ pkgs, ... }: {
          virtualisation = {
            memorySize = 8192;
            cores = 4;
            diskSize = 80 * 1024;
            writableStoreUseTmpfs = false;
          };
          nixos-shell.mounts.mountHome = false;
          boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
          boot.kernelPackages = pkgs.linuxPackages_latest;
          environment.systemPackages = with pkgs; [
            vim
            git
            btop
          ];
          services.mingetty.autologinUser = "root";
          nix = {
            settings = {
              trusted-users = [ "@wheel" "root" ];
              auto-optimise-store = true;
            };
            package = pkgs.nixUnstable;
            extraOptions =
              let empty_registry = builtins.toFile "empty-flake-registry.json" ''{"flakes":[],"version":2}''; in
              ''
                experimental-features = nix-command flakes
                flake-registry = ${empty_registry}
                builders-use-substitutes = true
              '';
            registry.nixpkgs.flake = inputs.nixpkgs;
            nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
          };
        })
      ];
    };
  };
}

