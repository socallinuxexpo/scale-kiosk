{ pkgs, lib, ... }:
let
  mouseUrl = "https://google.com";
  regularUrl = "https://duckduckgo.com";
  kioskProgram = pkgs.writeShellScript "kiosk.sh" ''
    cd /home/kiosk
    MOZ_ENABLE_WAYLAND=1 ${lib.getExe pkgs.firefox}
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
