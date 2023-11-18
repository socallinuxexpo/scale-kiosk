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
            pi-eeprom-sdImage = (self.nixosConfigurations.pi-eeprom.extendModules {
              modules = [ "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix" ];
            }).config.system.build.sdImage;
            build-eeprom = lib.mkOverridable
              { flash ? true }:
                let
                  bootconf = pkgs.writeText "bootconf" ''
                    [all]
                    BOOT_UART=1
                    WAKE_ON_GPIO=1
                    POWER_OFF_ON_HALT=0
                    ENABLE_SELF_UPDATE=1
                    BOOT_ORDER=0xf2 # 2=Network boot 1=sdcard, order matters
                    NET_BOOT_MAX_RETRIES=5
                    USE_IPV6=1 # Enable IPv6, netboot is on by default

                    [none]
                    FREEZE_VERSION=0
                  '';
                  pkgs = nixpkgs.legacyPackages.aarch64-linux;
                  pieeprom = if flash then "pieeprom.bin" else "pieeprom.upd";
                in
                pkgs.runCommand "eeprom.img"
                  {
                    buildInputs = [ pkgs.raspberrypi-eeprom ];
                  } ''
                    mkdir $out
                    # Apply config
                    echo ${bootconf}
                    rpi-eeprom-config --config ${bootconf} --out $out/${pieeprom} ${pkgs.raspberrypi-eeprom}/share/rpi-eeprom/latest/pieeprom-2023-01-11.bin
                    sha256sum $out/${pieeprom} | cut -d' ' -f1 > $out/pieeprom.sig
                    cp ${pkgs.raspberrypi-eeprom}/share/rpi-eeprom/latest/recovery.bin $out/recovery.bin
                    # This needs to increase after every update to the eeprom
                    echo 'ts: 102' >> $out/pieeprom.sig
                  '';
              );
            };
          };
          nixosConfigurations = {
            pi-kiosk = nixpkgs.lib.nixosSystem {
              system = "aarch64-linux";
              modules = [
                nixos-hardware.nixosModules.raspberry-pi-4
                ./configuration.nix
                ./base.nix
              ];
            };
            pi-eeprom = nixpkgs.lib.nixosSystem {
              system = "aarch64-linux";
              modules = [
                nixos-hardware.nixosModules.raspberry-pi-4
                ./base.nix
                ({ pkgs, ... }: {
                  environment.systemPackages = with pkgs; [ raspberrypi-eeprom ];
                  # without this we dont actually get a shell
                  boot.kernelParams = [
                    "console=ttyS0,115200"
                    "console=tty1"
                  ];
                })
              ];
            };

          };
        };
      };
    }
