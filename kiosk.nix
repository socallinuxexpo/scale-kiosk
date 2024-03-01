{ pkgs, lib, config, ... }:
let
  mouseUrl = "https://register.socallinuxexpo.org/reg6/?kiosk=1";
  regularUrl = "http://signs.scale.lan/";
  kioskProgram = pkgs.writeShellScript "kiosk.sh" ''
    cd /home/kiosk
    # account for ALT+F4 closing window in wayland
    while true
    do
      if [ -e /sys/class/input/mouse1 ]
      then
        # required cross-origin-iframe and popup blocking flags due to iframe
        ${lib.getExe pkgs.chromium} --blink-settings=allowScriptsToCloseWindows=true --ozone-platform=wayland --user-agent="SCALE:1" --disable-popup-blocking --disable-throttle-non-visible-cross-origin-iframes --incognito --start-maximized --disable-gpu --kiosk ${mouseUrl}
      else
        ${lib.getExe pkgs.chromium} --ozone-platform=wayland --incognito --start-maximized --disable-gpu --kiosk ${regularUrl}
      fi
    done
  '';
in
{
  # Disable CTRL keys
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = ["*"];
        settings = {
          main = {
            control = "noop";
          };
        };
      };
    };
  };
  users.users.kiosk = {
    isNormalUser = true;
    password = "changeme";
    extraGroups = [ "wheel" ];
  };
  services.cage = {
    enable = true;
    user = "kiosk";
    program = kioskProgram;
    environment = {
      WLR_LIBINPUT_NO_DEVICES = "1"; # boot up even if no mouse/keyboard connected
    };
  };
}
