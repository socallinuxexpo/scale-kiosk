{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixos-shell.url = "github:Mic92/nixos-shell";
    flake-parts.url = "github:hercules-ci/flake-parts";
    go-signs.url = "github:kylerisse/go-signs";
  };
  outputs = { self, nixpkgs, nixos-hardware, nixos-shell, flake-parts, go-signs }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./flake-modules/binfmt-sdk.nix
      ];
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      perSystem = { system, pkgs, ... }: let
        makeVmScript = config: (nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          inherit system;
          modules = [
            { inherit config; }
            ./configuration.nix
            ./base.nix
            ./prometheus.nix
            ({ config, ... }: {
              services.timesyncd.enable = pkgs.lib.mkForce true;
              system.build.vmScript = ((pkgs.writeShellScriptBin "stateless-kiosk-vm" ''
                TMPDIR=$(mktemp -d)
                function cleanup {
                  rm -rf "$TMPDIR"
                }
                trap cleanup 0
                cd $TMPDIR
                # screw up the clock so that a lack of RTC be emulated in VM
                ${pkgs.lib.getExe config.system.build.vm} \
                  -serial stdio \
                  -rtc base=1970-01-01T12:12:12,clock=vm,driftfix=slew \
                  "$@"
              ''));
            })
          ];
        }).config.system.build.vmScript;

      in {
        # Makes `nix run` work with .#vm .#vm.nomouse or .#vm.simulator
        legacyPackages = rec {
          vm = (makeVmScript {}).overrideAttrs {
            passthru = {
              # runs all variants of the VM defined in passthru, in a subshell at once
              all = pkgs.writeShellScriptBin "run-all-vms" ''
                ( ${pkgs.lib.getExe vm} &
                  ${pkgs.lib.concatStringsSep " & \n" (
                    map (v: pkgs.lib.getExe v) (builtins.attrValues (builtins.removeAttrs vm.passthru ["all"]))
                  )} &
                  wait )
              '';
              # Removes the mouse from /sys/class/input/mouse1, by blacklisting
              nomouse = makeVmScript {
                boot.blacklistedKernelModules = [ "hid-generic" "i8042" ];
              };
              # Same as nomouse, but overrides go-signs to use the simulator, json
              nomouse-with-simulator = makeVmScript {
                boot.blacklistedKernelModules = [ "hid-generic" "i8042" ];
                services.go-signs.simulator = true;
              };
            };
          };
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
            specialArgs = { inherit inputs; };
            modules = [
              nixos-hardware.nixosModules.raspberry-pi-4
              ./configuration.nix
              ./base.nix
              ./prometheus.nix
            ];
          };
        };
      };
    };
}

