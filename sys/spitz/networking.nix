{
  lib,
  pkgs,
  ...
}: let
  wlan = "wlp1s0";
in {
  systemd.network = {
    enable = true;
    networks."10-cameo-net" = {
      matchConfig.Name = wlan;
      DHCP = "yes";
      # keeps failing over, cache flushes, thrashing occurs
      dhcpV4Config.UseDNS = false;
      networkConfig.Tunnel = "he-ipv6";
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
        Local = "192.168.0.253";
        Remote = "74.82.46.6";
        TTL = 255;
      };
    };
    networks."13-he-tunnel" = let
      pfx = "2001:470:23:1c3:";
    in {
      matchConfig.Name = "he-ipv6";
      address = ["${pfx}:2/64"];
      gateway = ["${pfx}:1"];
      dns = ["2001:4860:4860::8844#dns.google"];
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
      ExecStart = lib.getExe (pkgs.writeShellApplication {
        name = "he-tunnel-update";
        runtimeInputs = [pkgs.xh];
        text = ''xhs "https://$(cat /etc/secrets/he-tunnel-update-auth)@ipv4.tunnelbroker.net/nic/update" hostname==568820'';
      });
      RootDirectory = "/run/he-tunnel-update";
      BindReadOnlyPaths = [
        "/nix/store"
        "/etc/secrets/he-tunnel-update-auth"
        "/etc/resolv.conf"
      ];
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
    Place $user:$pass file in /etc/secrets/he-tunnel-update-auth.
    See https://ipv4.tunnelbroker.net/tunnel_detail.php?tid=568820
  '';
  njx.wireguardToDoggieworld = {
    # wu3G78lGZRcQ5AqDL66bmrRPHpWOK7BCIhJhcjMofwM=
    enable = true;
    listenPort = 30985;
    finalOctet = 14;
  };
}
