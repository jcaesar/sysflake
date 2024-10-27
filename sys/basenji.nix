{lib, ...}: let
  private = import ../../private.nix;
in {
  njx.base = true;
  users.users.root.openssh.authorizedKeys.keys = private.terminalKeys;

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = true;
  boot.kernelParams = ["console=ttyS0,115200n8"];
  boot.initrd.systemd.enable = true;
  security.acme.defaults.email = "letsencrypt-n" + "@" + "liftm.de";
  security.acme.acceptTerms = true;
  services.qemuGuest.enable = true;
  services.airsonic = {
    enable = true;
    virtualHost = "funk.liftm.de";
  };
  services.nginx.enable = true;
  services.nginx.virtualHosts."funk.liftm.de" = {
    forceSSL = true;
    enableACME = true;
  };
  services.smartd.enable = lib.mkForce false;
  systemd.network = {
    enable = true;
    networks."10-main" = {
      matchConfig.Name = "enp2s0";
      DHCP = "no";
      address = ["10.13.43.14/24"];
      gateway = ["10.13.43.1.1"];
      dns = ["10.13.43.1"];
    };
  };

  fileSystems."/mnt/host" = {
    fsType = "virtiofs";
    device = "host";
  };
  disko.devices.disk.diks = {
    device = "/dev/vda";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        mbr = {
          size = "1M";
          type = "EF02";
        };
        boot = {
          type = "EF00";
          size = "500M";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "btrfs";
            mountpoint = "/";
            mountOptions = ["defaults" "discard=async" "relatime" "compress=zstd"];
          };
        };
      };
    };
  };

  system.stateVersion = "24.11";
}
