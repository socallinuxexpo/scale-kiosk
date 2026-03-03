# Monitoring kiosk module -- Cage + Chromium displaying Grafana dashboards.
# Modeled on kiosk.nix but simplified: single URL, no mouse detection, no go-signs.
# See docs/tdd/kiosk-monitoring.md for design rationale.
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.kiosk-monitoring;
  kioskProgram = pkgs.writeShellScript "kiosk-monitoring.sh" ''
    LAST_OCTET=$(ip -j route | ${lib.getExe pkgs.jq} '.[] | select(.dst == "default") | .prefsrc | split(".") | .[-1]' -r)
    cd /home/kiosk
    if [ ! -f /home/kiosk/kiosk.id ]; then
      KIOSK_ID=$(tr -dc 'a-zA-Z' < /dev/urandom | head -c 10)
      echo "KIOSK_ID=$KIOSK_ID" > /home/kiosk/kiosk.id
    fi
    source /home/kiosk/kiosk.id
    # account for ALT+F4 closing window in wayland
    while true
    do
      ${lib.getExe pkgs.ungoogled-chromium} \
        --ignore-certificate-errors \
        --user-agent="$KIOSK_ID:$LAST_OCTET" \
        --incognito \
        --start-maximized \
        --disable-gpu \
        --kiosk \
        --app='${cfg.url}'
    done
  '';
in
{
  options.services.kiosk-monitoring = {
    url = lib.mkOption {
      type = lib.types.str;
      default = "https://core-conf.scale.lan/grafana";
      description = "URL to display in the monitoring kiosk";
    };
  };
  config = {
    # Disable CTRL keys
    services.keyd = {
      enable = true;
      keyboards = {
        default = {
          ids = [ "*" ];
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
    systemd.services.dynamic-scale =
      let
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
      in
      {
        description = "Dynamically Configure DPI based on Resolution";
        wantedBy = [ "graphical.target" ];
        partOf = [ "graphical.target" ];
        after = [ "cage-tty1.service" ];
        path = with pkgs; [
          wlr-randr
          jq
        ];

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
  };
}
