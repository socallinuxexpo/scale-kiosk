{ pkgs, lib, ... }:
let
  mouseUrl = "https://register.socallinuxexpo.org/reg6/kiosk/";
  regularUrl = "http://signs.scale.lan/";
  kioskProgram = pkgs.writeShellScript "kiosk.sh" ''
    cd /home/kiosk
    # account for ALT+F4 closing window in wayland
    while true
    do
      if [ -e /sys/class/input/mouse0 ]
      then
        # required cross-origin-iframe and popup blocking flags due to iframe
        MOZ_ENABLE_WAYLAND=1 ${lib.getExe pkgs.firefox} --kiosk --private-window ${mouseUrl}
      else
        MOZ_ENABLE_WAYLAND=1 ${lib.getExe pkgs.firefox} --kiosk --private-window ${regularUrl}
      fi
    done
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
    environment = {
      WLR_LIBINPUT_NO_DEVICES = "1"; # boot up even if no mouse/keyboard connected
    };
  };
}
