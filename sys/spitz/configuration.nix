{
  pkgs,
  lib,
  ...
}: let
  private = import ../../private.nix;
in {
  imports = [
    ./mtx.nix
    ./networking.nix
    ./filesystems.nix
  ];
  networking.hostName = "spitz";
  networking.domain = "liftm.de";
  njx.base = true;
  njx.sshUnlock.modules = ["igc" "rtw89_8852be"];
  njx.sshUnlock.keys = private.terminalKeys;
  users.users.root.openssh.authorizedKeys.keys = private.terminalKeys;
  services.openssh.enable = true;

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 15;
      editor = false;
    };
    efi.canTouchEfiVariables = true;
  };
  boot.initrd.systemd.enable = true;

  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql_16;
  services.nginx.enable = true;
  security.acme.defaults.email = "letsencrypt-n" + "@" + "liftm.de";
  security.acme.acceptTerms = true;
  services.prometheus.exporters.node = {
    enable = true;
    njx.powercap = true;
  };
  # todo: modulize
  networking.firewall = let
    rulesAllowSport = sign: ''
      ip46tables -${sign} nixos-fw -i wg0 -p tcp -m tcp --dport 9100 -j nixos-fw-accept
    '';
  in {
    allowedTCPPorts = [80 443];
    extraCommands = rulesAllowSport "A";
    extraStopCommands = rulesAllowSport "D";
  };

  system.stateVersion = "24.11";
}
