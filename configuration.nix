{ pkgs, config, ... }:
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
}
