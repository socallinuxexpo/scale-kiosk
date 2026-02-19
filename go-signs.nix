{ lib, config, pkgs, inputs, ... }:
let
  cfg = config.services.go-signs;
in
{
  options = {
    services.go-signs = {
      enable = lib.mkEnableOption "go-signs service";
      simulator = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Use simulator JSON endpoint";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = inputs.go-signs.packages.${pkgs.hostPlatform.system}.go-signs;
        description = "go-signs package to use";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.go-signs = {
      description = "SCaLE go-signs server";
      wantedBy = [ "multi-user.target" ];
      before = [ "graphical.target" ];
      after = [ "network.target" "network-online.target" "time-sync.target" ];
      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        ExecStart = "${cfg.package}/bin/go-signs ${lib.optionalString cfg.simulator " -json=https://simulator.go-signs.org/sign.json"}";
      };
    };
  };
}
