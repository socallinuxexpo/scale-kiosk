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
        ${lib.getExe pkgs.ungoogled-chromium} --blink-settings=allowScriptsToCloseWindows=true --user-agent="SCALE:$LAST_OCTET" --disable-popup-blocking --disable-throttle-non-visible-cross-origin-iframes --incognito --start-maximized --disable-gpu --kiosk ${mouseUrl}
      else
        ${lib.getExe pkgs.ungoogled-chromium} --incognito --start-maximized --disable-gpu --kiosk ${regularUrl}
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
            alt = "noop";
            leftalt = "noop";
            rightalt = "noop";
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
  systemd.services.dynamic-scale = let
    dynamic-scale = pkgs.writeShellScript "dynamic-scale.sh" ''
      set -x
      # Get the JSON output from wlr-randr
      output_json=$(wlr-randr --json)
      # Use jq to find outputs and their resolutions
      echo "$output_json" | jq -c '.[] | {name: .name, height: .modes[0].height}' | while read -r output; do
          # Extract monitor name and height
          name=$(echo "$output" | jq -r '.name')
          height=$(echo "$output" | jq -r '.height')
          # Calculate scale dynamically based on height
          if [ "$height" -ge 1080 ]; then
              scale=1.0
          fi
          if [ "$height" -ge 1440 ]; then
              scale=1.33
          fi
          if [ "$height" -ge 2160 ]; then
              scale=2.0
          fi
          if [ "$height" -ge 4320 ]; then
              scale=4.0
          fi
          # Apply the scale
          echo "Setting scale $scale for $name (height: $height)"
          wlr-randr --output "$name" --scale "$scale"
      done
    '';
  in {
    description = "Dynamically Configure DPI based on Resolution";
    wantedBy = [ "graphical.target" ];
    partOf = [ "graphical.target" ];
    after = [ "cage-tty1.service" ];
    path = with pkgs; [ wlr-randr jq ];

    # Probably possible to do this with systemd user services instead
    # https://www.baeldung.com/linux/systemd-session-dbus-headless-setup
    environment.XDG_RUNTIME_DIR = "/run/user/1000";
    environment.WAYLAND_DISPLAY = "wayland-0";

    serviceConfig = {
      Type = "simple";
      User = "kiosk";
      ExecStart = "${dynamic-scale}";
      Restart = "always";
      RestartSec = 5;
    };
  };
}
