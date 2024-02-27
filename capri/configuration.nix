{
  pkgs,
  lib,
  ...
}: let
  common = import ../work.nix;
  eth = "ens32";
in rec {
  imports = [
    ../common.nix
    common.config
    ./hardware-configuration.nix
  ];

  boot.initrd.luks.devices = {
    crypt = {
      # cryptsetup conrig /dev/foo --label crypt
      device = "/dev/disk/by-label/crypt";
      preLVM = true;
      allowDiscards = false;
    };
  };
  services.smartd.enable = lib.mkForce false;

  # remote unlock: ssh -tt capri-init systemd-cryptsetup attach crypt /dev/disk/by-label/crypt
  boot.initrd.kernelModules = ["e1000"];
  boot.initrd.systemd = {
    enable = true;
    network = {
      enable = true;
      networks = systemd.network.networks;
    };
  };
  boot.initrd.network.enable = true;
  boot.initrd.network.ssh = {
    enable = true;
    port = 2223;
    hostKeys = [
      "/etc/ssh/boot/host_rsa_key"
      "/etc/ssh/boot/host_ed25519_key"
    ];
    authorizedKeys = common.sshKeys.strong;
  };
  systemd.enableEmergencyMode = false;

  networking.proxy.default = common.proxy "julius9dev9gemini1" "7049740682";
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks."10-vm-${eth}" = {
      matchConfig.Name = eth;
      DHCP = "no";
      address = ["10.38.90.22/24"];
      gateway = ["10.38.90.1"];
      dns = common.dns;
    };
  };
  networking.hostName = "capri";

  users.users.julius = {
    extraGroups = ["wheel" "docker"];
    openssh.authorizedKeys.keys = common.sshKeys.client;
  };
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = common.packages pkgs;
  #programs.direnv.nix-direnv.enable = true; TODO: IDGI

  services.acpid.enable = true; # Was supposed to prevent shutdown hang, doesn't
  virtualisation.vmware.guest.enable = true;

  networking.firewall.allowedTCPPorts = [2222 2223 1337];
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
