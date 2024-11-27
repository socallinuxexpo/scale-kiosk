{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ kanshi ];
  systemd.services.kanshi = {
    description = "kanshi dynamic display congfiguration daemon";
    wantedBy = [ "graphical.target" ];
    partOf = [ "graphical.target" ];
    after = [ "cage-tty1.target" ];
    environment.XDG_RUNTIME_DIR = "/run/user/1000";
    environment.WAYLAND_DISPLAY = "wayland-0";
    serviceConfig = {
      Type = "simple";
      User = "kiosk";
      ExecStart = ''${pkgs.kanshi}/bin/kanshi -c /etc/kanshi/config'';
    };
  };
  environment.etc."kanshi/config" = {
    text = ''
      output * mode 7680x4320 scale 3
      output * mode 3840x2160 scale 2
      output * mode 1920x1080 scale 1
      output * scale 1
    '';
    mode="0644";
  };
}
