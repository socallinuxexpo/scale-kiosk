{ pkgs, lib, config, modulesPath, ... }:
{
  imports = [
    ./kiosk.nix
    "${modulesPath}/profiles/minimal.nix"
  ];
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

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

  # Sync via NTP before allowing multi-user.target
  # https://discourse.nixos.org/t/systemd-wait-for-timesync/15808/2
  systemd = {
    additionalUpstreamSystemUnits = [ "systemd-time-wait-sync.service" ];
    services.systemd-time-wait-sync.wantedBy = [ "multi-user.target" ];
    services."cage-tty1".after = [ "network.target" "time-sync.target" ];
  };
}
