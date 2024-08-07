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

  networking.firewall.allowedTCPPorts = [80 443];
  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql_16;
  services.nginx.enable = true;
  security.acme.defaults.email = "letsencrypt-n" + "@" + "liftm.de";
  security.acme.acceptTerms = true;

  system.stateVersion = "24.11";
}
