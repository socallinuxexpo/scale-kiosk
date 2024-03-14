{ pkgs, lib, ... }:
let
  mouseUrl = "https://register.socallinuxexpo.org/reg6/?kiosk=1";
  regularUrl = "http://signs.scale.lan/";
  # using electron should be preferable, but in practice it has some
  # quirks that make using chromium better
  kioskProgram = pkgs.writeShellScript "kiosk.sh" ''
    LAST_OCTET=$(ip -j route | ${lib.getExe pkgs.jq} '.[] | select(.dst == "default") | .prefsrc | split(".") | .[-1]' -r)
    cd /home/kiosk
    # account for ALT+F4 closing window in wayland
    while true
    do
      if [ -e /sys/class/input/mouse1 ]
      then
        # required cross-origin-iframe and popup blocking flags due to iframe
        ${lib.getExe pkgs.ungoogled-chromium} --force-device-scale-factor=2.0 --blink-settings=allowScriptsToCloseWindows=true --user-agent="SCALE:$LAST_OCTET" --disable-popup-blocking --disable-throttle-non-visible-cross-origin-iframes --incognito --start-maximized --disable-gpu --kiosk ${mouseUrl}
      else
        ${lib.getExe pkgs.ungoogled-chromium} --force-device-scale-factor=2.0 --incognito --start-maximized --disable-gpu --kiosk ${regularUrl}
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
