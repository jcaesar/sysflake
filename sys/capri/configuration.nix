{
  pkgs,
  lib,
  ...
}: let
  common = import ../../work.nix;
  eth = "ens32";
in {
  imports = [
    ../../mod/common.nix
    ../../mod/binfmt.nix
    ../../mod/squid.nix
    common.config
    ./hardware-configuration.nix
    (import ../../mod/ssh-unlock.nix {
      authorizedKeys = common.sshKeys.strong;
      extraModules = ["e1000"];
    })
  ];

  boot.initrd.luks.devices = {
    crypt = {
      # cryptsetup config /dev/foo --label crypt
      device = "/dev/disk/by-label/crypt";
      preLVM = true;
      allowDiscards = false;
    };
  };
  services.smartd.enable = lib.mkForce false;

  networking.proxy.default = "http://10.13.24.255:3128/";
  systemd.network = {
    enable = true;
    networks."10-vm-${eth}" = {
      matchConfig.Name = eth;
      DHCP = "no";
      address = ["10.38.90.22/24"];
      gateway = ["10.38.90.1"];
      dns = common.dns;
    };
    netdevs."8-stubbytoe".netdevConfig = {
      Name = "stubbytoe";
      Kind = "dummy";
      MACAddress = "de:ad:be:ef:ca:fe";
    };
    networks."9-stubbytoe" = {
      matchConfig.Name = "stubbytoe";
      address = ["10.13.24.255/32"];
    };
  };
  networking.hostName = "capri";

  users.users.julius = {
    extraGroups = ["wheel" "docker"];
    openssh.authorizedKeys.keys = common.sshKeys.client;
  };
  users.users.aoki = {
    openssh.authorizedKeys.keys = common.sshKeys.aoki;
    isNormalUser = true;
  };
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = common.packages pkgs;
  #programs.direnv.nix-direnv.enable = true; TODO: IDGI

  services.acpid.enable = true; # Was supposed to prevent shutdown hang, doesn't
  virtualisation.vmware.guest.enable = true;

  networking.firewall.allowedTCPPorts = [2223 1337];
  networking.firewall.allowedUDPPorts = [];
  networking.firewall.enable = true;

  #system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  #fileSystems."/boot" =
  #  { device = "/dev/disk/by-label/boot";
  #    fsType = "vfat";
  #  };
}
