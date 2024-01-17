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
        ${lib.getExe pkgs.chromium} --ozone-platform=wayland --disable-popup-blocking --disable-throttle-non-visible-cross-origin-iframes --incognito --start-maximized --kiosk ${mouseUrl}
      else
        ${lib.getExe pkgs.chromium} --ozone-platform=wayland --incognito --start-maximized --kiosk ${regularUrl}
      fi
    done
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

  # Whitelist wheel users to do anything
  # This is useful for things like pkexec
  #
  # WARNING: this is dangerous for systems
  # outside the installation-cd and shouldn't
  # be used anywhere else.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';
}
