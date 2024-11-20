{
  lib,
  pkgs,
  ...
}: let
  common = import ../../work.nix;
  eth = "ens32";
in {
  imports = [
    ./hardware-configuration.nix
    ./log-to-aws.nix
    ./pua.nix
  ];
  njx.common = true;
  njx.work = true;

  boot.initrd.luks.devices = {
    crypt = {
      # cryptsetup config /dev/foo --label crypt
      device = "/dev/disk/by-label/crypt";
      preLVM = true;
      allowDiscards = false;
    };
  };
  services.smartd.enable = lib.mkForce false;
  njx.sshUnlock.keys = common.sshKeys.strong;
  njx.sshUnlock.modules = ["e1000"];

  systemd.network = {
    enable = true;
    networks."10-vm-${eth}" = {
      matchConfig.Name = eth;
      DHCP = "no";
      address = ["10.38.90.22/24"];
      gateway = ["10.38.90.1"];
      dns = common.dnsG;
    };
  };
  networking.hostName = "capri";

  users.users.julius = {
    extraGroups = ["wheel" "docker"];
    openssh.authorizedKeys.keys = common.sshKeys.client;
  };
  users.users.aoki = {
    # used it to exchange data before. project gone.
    openssh.authorizedKeys.keys =
      map
      (k: "no-port-forwarding,no-agent-forwarding ${k}")
      (common.sshKeys.aoki ++ common.sshKeys.client);
    shell = lib.getExe' pkgs.git "git-shell";
    isNormalUser = true;
  };
  security.sudo.wheelNeedsPassword = false;

  #programs.direnv.nix-direnv.enable = true; TODO: IDGI

  services.acpid.enable = true; # Was supposed to prevent shutdown hang, doesn't
  virtualisation.vmware.guest.enable = true;
  virtualisation.docker.rootless.enable = false;

  networking.firewall.allowedTCPPorts = [2223 1337];
  networking.firewall.allowedUDPPorts = [];
  networking.firewall.enable = true;
  system.stateVersion = "23.05"; # Did you read the comment?
}
