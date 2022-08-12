{ pkgs, lib, ... }:
let
  mouseUrl = "https://google.com";
  regularUrl = "https://duckduckgo.com";
  kioskProgram = pkgs.writeShellScript "kiosk.sh" ''
    if [ -e /sys/class/input/mouse0 ]
    then
      ${lib.getExe pkgs.chromium} --disable-infobars --start-maximized --kiosk ${mouseUrl}
    else
      ${lib.getExe pkgs.chromium} --disable-infobars --start-maximized --kiosk ${regularUrl}
    fi
  '';
in
{
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
