{ pkgs, lib, config, ... }:
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
        ${lib.getExe pkgs.chromium} --ozone-platform=wayland --disable-popup-blocking --disable-throttle-non-visible-cross-origin-iframes --incognito --start-maximized --disable-gpu --disable-extensions --kiosk ${mouseUrl}
      else
        ${lib.getExe pkgs.chromium} --ozone-platform=wayland --incognito --start-maximized --disable-gpu --kiosk ${regularUrl}
      fi
    done
  '';
in
  {
  services.getty.autologinUser = lib.mkForce "kiosk";
  users.users.kiosk = {
    isNormalUser = true;
    password = "changeme";
    extraGroups = [ "wheel" ];
  };

  systemd.services."cage-tty1".serviceConfig =
  let
    cfg = config.services.cage;
  in
  lib.mkForce { 
        ExecStart = ''
          ${pkgs.cage}/bin/cage \
            -- ${cfg.program}
        '';
        User = cfg.user;

        IgnoreSIGPIPE = "no";

        # Log this user with utmp, letting it show up with commands 'w' and
        # 'who'. This is needed since we replace (a)getty.
        UtmpIdentifier = "%I";
        UtmpMode = "user";
        # A virtual terminal is needed.
        TTYPath = "/dev/tty1";
        TTYReset = "yes";
        TTYVHangup = "yes";
        TTYVTDisallocate = "yes";
        # Fail to start if not controlling the virtual terminal.
        StandardInput = "tty-fail";
        StandardOutput = "journal";
        StandardError = "journal";
        # Set up a full (custom) user session for the user, required by Cage.
        PAMName = "cage";
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
