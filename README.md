# TODO

- Create a netbootable netbootImage output instead of sdImage
- Provide a nixosConfiguration for this netbootImage that runs all of the infrastructure for booting it via PXE and other methods
- Derive configuration values from the scale-network repo as a Flake input, or
  merge with the scale-network repository
  - Merging with the scale-network repository requires requires refactoring of that
  repository, or else it is not worth merging with it. This kiosk repository is better as a separate Flake until refactoring and more Nixification occurs upstream in the scale-network repository.

## Building

If you're already on NixOS and have Nix installed and can emulate arm64 transparently then just:

`nix build .#pi-kiosk-sdImage`

Otherwise, follow the instructions below before running this command.

### x86_64-linux (NixOS)

If you're running NixOS and want to use this template to build the Raspberry Pi
4 Image, you'll need to emulate an arm64 machine by adding the following to your
NixOS configuration.

```
{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
```

Then you will be able to run `nix build .#pi-kiosk-sdImage` and get a result
you can flash to an SD Card and boot.

After you've booted, you can rebuild the `nixosConfiguration` on
the Pi. For example, by running `nixos-rebuild --flake
socallinuxexpo/scale-kiosk#pi-kiosk` and should never have to re-image again unless you want to.

### On x86_64-linux (any distribution of Linux)

Get Nix and enable flakes, for example via the DetSys Nix installer

```
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Or if you prefer a single 21M~ file, get a statically compiled Nix binary

```
curl -L https://hydra.nixos.org/job/nix/master/buildStatic.x86_64-linux/latest/download-by-type/file/binary-dist > nix
chmod +x ./nix
```

Run the Binfmt SDK from the root of this repo in order to enter a virtual
machine which is itself capable of emulating arm64. You will then be able to
clone the repo and build any of the arm64 outputs from this flake.

`nix run .#binfmt-sdk-nixos-shell`

### What is binfmt and why is it needed?

To avoid the need to cross-compile anything, and to make use of
cache.nixos.org, building via binfmt will actually spin up QEMU and emulate an
arm64 machine for every package/derivation that needs to be compiled. Binfmt is
a kernel feature that will allows programs like QEMU to be span up whenever any
program tries to spawn a process for a foreign architecture.

