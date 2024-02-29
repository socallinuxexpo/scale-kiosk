{ pkgs, lib, config, ... }:
{
  imports = [ ./kiosk.nix ];
  # default to stateVersion for current lock
  system.stateVersion = config.system.nixos.version;
  services.openssh.enable = true;
  networking.hostName = "pi";
  users = {
    users.myUsername = {
      password = "myPassword";
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };
  nix.settings = {
    experimental-features = lib.mkDefault "nix-command flakes";
    trusted-users = [ "root" "@wheel" ];
  };
  # This causes an overlay which causes a lot of rebuilding
  environment.noXlibs = lib.mkForce false;
}
