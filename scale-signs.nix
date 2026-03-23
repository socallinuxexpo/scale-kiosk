{ lib, config, pkgs, inputs, ... }:
let
  cfg = config.services.scale-signs;
in
{
  options = {
    services.scale-signs = {
      enable = lib.mkEnableOption "scale-signs service";
      simulator = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Use simulator JSON endpoint";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = inputs.scale-signs.packages.${pkgs.hostPlatform.system}.scale-signs;
        description = "scale-signs package to use";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.scale-signs = {
      description = "SCaLE scale-signs server";
      wantedBy = [ "multi-user.target" ];
      before = [ "graphical.target" ];
      after = [ "network.target" "network-online.target" "time-sync.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        ExecStart = "${cfg.package}/bin/scale-signs ${lib.optionalString cfg.simulator " -json=https://simulator.scalenoc.org/sign.json"}";
      };
    };
  };
}
