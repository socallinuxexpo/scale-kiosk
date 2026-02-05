{ inputs, pkgs, ... }:
{
systemd.services.go-signs = {
  description = "SCaLE go-signs server";
  wantedBy = [ "multi-user.target" ];
  before = [ "graphical.target" ];
  after = [ "network.target" "network-online.target" "time-sync.target" ];
  serviceConfig = {
    Type = "simple";
    DynamicUser = true;
    ExecStart = "${inputs.go-signs.packages.${pkgs.hostPlatform.system}.go-signs}/bin/go-signs";
  };
};
}
