{pkgs, ...}: let
  private = import ../../private.nix;
  wlan = "wlp1s0";
in {
  imports = [./mtx.nix];
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

  systemd.network = {
    enable = true;
    networks."10-cameo-net" = {
      matchConfig.Name = wlan;
      DHCP = "yes";
      dns = ["1.1.1.1"];
      # keeps failing over, cache flushes, thrashing occurs
      dhcpV4Config.UseDNS = false;
    };
  };
  networking.supplicant.${wlan} = {
    configFile.writable = true;
    configFile.path = "/etc/wpa_supplicant.conf";
  };
  networking.wireless.userControlled.enable = true;

  boot.supportedFilesystems = ["bcachefs"];
  disko.devices.disk.diks = {
    device = "/dev/nvme0n1";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          type = "EF00";
          size = "1G";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        root = {
          size = "300G";
          content = {
            type = "luks";
            name = "nixcrypt";
            settings.allowDiscards = true;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = ["defaults" "relatime"];
            };
          };
        };
        store = {
          size = "100G";
          content = {
            type = "filesystem";
            format = "bcachefs";
            mountpoint = "/nix/store";
          };
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [80 443];
  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql_16;
  services.nginx.enable = true;
  security.acme.defaults.email = "letsencrypt-n" + "@" + "liftm.de";
  security.acme.acceptTerms = true;

  system.stateVersion = "24.11";
}
