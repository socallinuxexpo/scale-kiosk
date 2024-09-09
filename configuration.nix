{ pkgs, lib, config, modulesPath, ... }:
{
  imports = [
    ./kiosk.nix
    "${modulesPath}/profiles/minimal.nix"
  ];
  # default to stateVersion for current lock
  system.stateVersion = config.system.nixos.version;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  hardware.graphics.enable = true;

  networking.hostName = "pi";
  users.users = {
    rob = {
      isNormalUser = true;
      uid = 2005;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMEiESod7DOT2cmT2QEYjBIrzYqTDnJLld1em3doDROq" ];
    };
    owen = {
      isNormalUser = true;
      uid = 2006;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBjjcUJLTENGrV6K/nrPOswcBVMMuS4sLSs0UyTRw8wU87PDUzJz8Ht2SgHqeEQJdRm1+b6iLsx2uKOf+/pU8qE= root@kiev.delong.com" ];
    };
    matt = {
      isNormalUser = true;
      uid = 2007;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJMi3TAuwDtIeO4MsORlBZ31HzaV5bji1fFBPcC9/tWuAAAABHNzaDo= nano-yubikey" ];
    };
    rhamel = {
      isNormalUser = true;
      uid = 2008;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICVZ7n1EOezedsbphq5atGtHm11xeGpLZBzEbgV7eZdb" ];
    };
    dlang = {
      isNormalUser = true;
      uid = 2009;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEqPnzsYPKyURdnUpZx1nt9RFQjaz9q7m5wh525Crsho" "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCtTtJZOyg/9/hbP6IuCyjpA1L0SqMR6wWOU8uJaoa3YlN2sqUkIGne1WYc+4jR+0F2uusDQ1Beb2a9Z0XGxP7nkEIGc5ontC6R/ZUHGf8axz5LXGk9VESR6sMdOjeotSYWwcuj6kPqa0XNXy0nG08dhe8Y+QkjiDQRhjMka4OOmcjMtRAjJyfhROEMpFM18M4Fh3+8j36TatzQQWO6wZ408dQYIc6ShleVfVCvEn5fZ0lm3BRe0UW3wfNs9qupk89VrfUWAEYqvh2uSz9SJBEkGAumreu6ASq7rfPC2DyI60vIT4uaRsqSzfQyT9o1n4v8WmgUKp4kRfZ+T8jWFoUXhj82+2WCCxUlq8D1SRcXDI1OQhHNmH7okorw7TgKJPdM0f96tvgdviH3As6xP/GdnEup8HL0nqKSX8dbRggS9xvmr5SKqGN8QSrclJ+cCsUOWRctgGasf7m+Q6XFNF/8LG6wbqBxxw7TLMLkjVdppHAFoewoBau5cRKGQ++G+BU=" ];
    };

  };

  security.sudo = {
    extraConfig = ''
      Defaults rootpw
            Defaults lecture="never"
    '';
  };

  users.mutableUsers = false;
  users.extraUsers.root.hashedPassword = "$6$3Hm/K5fbR3UEMK6H$3aaegtdwvejGk9Bk0ttN5bNJn4z2Yt6LWXD3nGI7.44Pbm7A1TpKuxG9XQLwsj7M9NEk8eB5Exg0qVRV//6br/";

  nix.settings = {
    experimental-features = lib.mkDefault "nix-command flakes";
    trusted-users = [ "root" "@wheel" ];
  };
  # This causes an overlay which causes a lot of rebuilding
  environment.noXlibs = lib.mkForce false;

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  boot.kernelParams = [ "cma=256M" ];

  # Sync via NTP before allowing multi-user.target
  # https://discourse.nixos.org/t/systemd-wait-for-timesync/15808/2
  systemd = {
    additionalUpstreamSystemUnits = [ "systemd-time-wait-sync.service" ];
    services.systemd-time-wait-sync.wantedBy = [ "multi-user.target" ];
    services."cage-tty1".after = [ "network.target" "time-sync.target" ];
  };

  # Reduces closure size
  nixpkgs.flake.setFlakeRegistry = false;
  nixpkgs.flake.setNixPath = false;
}
