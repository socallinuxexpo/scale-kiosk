{ pkgs, lib, ... }:
let
  mouseUrl = "https://google.com";
  regularUrl = "https://duckduckgo.com";
  kioskProgram = pkgs.writeShellScript "kiosk.sh" ''
    MOZ_ENABLE_WAYLAND=1 ${lib.getExe pkgs.firefox}
  '';
in
  {
  services.getty.autologinUser = "kiosk";
  users.users.kiosk = {
    isNormalUser = true;
    password = "changeme";
    extraGroups = [ "wheel" ];
  };
  services.cage = {
    enable = true;
    user = "kiosk";
    program = kioskProgram;
  };
}
