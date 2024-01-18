{ pkgs, ... }:
{
  imports = [ ./kiosk.nix ];
  environment.systemPackages = with pkgs; [ vim git seatd ];
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
