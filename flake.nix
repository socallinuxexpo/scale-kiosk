{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixos-shell.url = "github:Mic92/nixos-shell";
    flake-parts.url = "github:hercules-ci/flake-parts";
    firmware = {
      flake = false;
      url = "github:raspberrypi/firmware";
    };
  };
  outputs = { self, nixpkgs, nixos-hardware, nixos-shell, firmware, flake-parts }@inputs:
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
              # enable timesyncd in the VM
              { services.timesyncd.enable = pkgs.lib.mkForce true; }
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
            ${pkgs.lib.getExe vmScript} \
              # screw up the clock so that a lack of RTC be emulated in VM
              -rtc base=1970-01-01T12:12:12,clock=vm,driftfix=slew
          '');
        };
      };
      flake = { ... }: {
        # We only ever want to build for arm64, even when the host is
        # x86_64-linux, maybe we should show a trace when building in order to be
        # more informative?
        packages.x86_64-linux.pi-kiosk-sdImage = self.packages.aarch64-linux.pi-kiosk-sdImage;
        packages.x86_64-linux.pi-kiosk-netbootRoot = self.packages.aarch64-linux.pi-kiosk-netbootRoot;
        packages.aarch64-linux = let
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
          eval = self.nixosConfigurations.pi-kiosk.extendModules {
            modules = [
              "${nixpkgs}/nixos/modules/installer/netboot/netboot.nix"
              {
#                fileSystems."/".fsType = pkgs.lib.mkForce "tmpfs";
                boot.initrd.postDeviceCommands = ''
                  tftp -g -r 1.2.3.4 path/nix-store.squashfs
                '';
                boot.loader.grub.enable = false;
                boot.initrd.network.enable = true;
                boot.initrd.extraUtilsCommandsTest = "$out/bin/tftp --help";
              }
            ];
          };
          initrd = eval.config.system.build.initialRamdisk;
#          initrd = eval.config.system.build.netbootRamdisk;
#          initrd = pkgs.makeInitrd {
#            contents = [
#              {
#                symlink = "/init";
#                object = "${eval.config.system.build.toplevel}/init";
#              }
#            ];
#          };
        in {
          pi-kiosk-netbootRoot = pkgs.runCommand "rpi-boot-pi-kiosk" {
            passthru.eval = eval;
            passAsFile = [ "configtxt" ];
            configtxt = ''
              kernel=${eval.config.system.boot.loader.kernelFile}
              initramfs initrd followkernel
            '';
          } ''
            mkdir $out
            cd $out
            cp ${initrd}/initrd initrd
            cp ${eval.config.system.build.squashfsStore} ./nix-store.squashfs
            cp $configtxtPath config.txt
            cp ${eval.config.system.build.kernel}/${eval.config.system.boot.loader.kernelFile} .
            cp -v ${firmware}/boot/{start4.elf,fixup4.dat} .
            cp -v ${eval.config.system.build.kernel}/dtbs/broadcom/bcm2711*.dtb .
          '';
          pi-kiosk-sdImage = (self.nixosConfigurations.pi-kiosk.extendModules {
            modules = [
              "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
              {
                disabledModules = [ "profiles/base.nix" ];
              }
            ];
          }).config.system.build.sdImage;
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
        };
      };
    };
}

