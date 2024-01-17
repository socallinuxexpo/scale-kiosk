{ pkgs, lib, ... }:
let
  mouseUrl = "https://register.socallinuxexpo.org/reg6/kiosk/";
  regularUrl = "http://signs.scale.lan/";
  kioskProgram = pkgs.writeShellScript "kiosk.sh" ''
    cd /home/kiosk
    if [ -e /sys/class/input/mouse0 ]
    then
      ${lib.getExe pkgs.chromium} --ozone-platform=wayland --disable-popup-blocking --disable-throttle-non-visible-cross-origin-iframes --incognito --start-maximized --kiosk ${mouseUrl}
    else
      ${lib.getExe pkgs.chromium} --ozone-platform=wayland --incognito --start-maximized --kiosk ${regularUrl}
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
