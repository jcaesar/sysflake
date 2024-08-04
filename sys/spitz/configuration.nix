{
  pkgs,
  lib,
  ...
}: let
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
    networks."11-ll" = {
      matchConfig.Name = "enp3s0";
      DHCP = "yes";
      linkConfig.RequiredForOnline = false;
    };
    netdevs."12-he-tunnel" = {
      netdevConfig = {
        Name = "he-ipv6";
        Kind = "sit";
        MTUBytes = toString 1480;
      };
      tunnelConfig = {
        Local = "192.168.0.243";
        Remote = "74.82.46.6";
        TTL = 255;
      };
    };
    networks."13-he-tunnel" = {
      matchConfig.Name = "he-ipv6";
      address = ["2001:470:1f0a:c81::2/64" "2001:470:1f0b:c82::1/64"];
      gateway = ["2001:470:1f0a:c81::1"];
    };
  };
  networking.supplicant.${wlan} = {
    configFile.writable = true;
    configFile.path = "/etc/wpa_supplicant.conf";
  };
  networking.wireless.userControlled.enable = true;
  # TODO: Modularize (with hostname option)
  systemd.tmpfiles.rules = [
    "D /run/he-tunnel-update 700 root root - -"
  ];
  systemd.services.he-tunnel-update = {
    serviceConfig = {
      ExecStart = pkgs.writeScript "he-tunnel-update" ''
        set -eu
        ${lib.getExe' pkgs.xh "xhs"} "https://$(cat /etc/secrets/he-tunnel-update-auth)@ipv4.tunnelbroker.net/nic/update" hostname==504322
      '';
      RootDirectory = "/run/he-tunnel-update";
      BindReadOnlyPaths = ["/nix/store" "/etc/secrets/he-tunnel-update-auth"];
    };
  };
  systemd.timers.he-tunnel-update = {
    timerConfig = {
      OnCalendar = "09:01:33 Asia/Tokyo"; # random
      OnBootSec = "300s";
    };
    wantedBy = ["timers.target"];
  };
  njx.manual.he-tunnel = ''
    Place $user:$pass file in /etc/secrets/he-tunnel-update-auth
  '';

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
