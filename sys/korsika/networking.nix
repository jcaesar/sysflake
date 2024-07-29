let
  palmarolaPort = "enp0s31f6";
  cameoPort = "enp2s0";
  common = import ../../work.nix;
in
  {pkgs, ...}: {
    systemd.network = {
      enable = true;
      networks."10-palmarola-eth-net" = {
        matchConfig.Name = palmarolaPort;
        DHCP = "no";
        address = ["10.13.25.2/24"];
      };
      netdevs."11-palmarola-wg-dev" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "gozo";
          MTUBytes = "1350";
        };
        wireguardConfig = {
          PrivateKeyFile = "/etc/secrets/gozo.pk";
          ListenPort = 36749;
        };
        wireguardPeers = [
          {
            PublicKey = "BThC89DqFj+nGtkCytNSskolwCijeyq/XDiAM8hQJRw=";
            Endpoint = "10.13.25.1:53";
            AllowedIPs = ["0.0.0.0/0"];
            PersistentKeepalive = 29;
          }
        ];
      };
      networks."12-palmarola-wg-net" = {
        matchConfig.Name = "gozo";
        address = ["10.13.26.2/24"];
        DHCP = "no";
        dns = ["10.13.26.1:5353"];
        ntp = common.ntp;
        gateway = ["10.13.26.1"];
        networkConfig.IPv6AcceptRA = false;
      };
    };

    systemd.network.networks."13-cameo" = {
      matchConfig.Name = cameoPort;
      DHCP = "ipv4";
      networkConfig = {
        IPv6AcceptRA = false;
      };
      dhcpV4Config = {
        UseRoutes = false;
        UseDNS = false;
      };
      linkConfig.RequiredForOnline = false;
    };

    environment.systemPackages = [pkgs.wireguard-tools];

    networking.firewall = {
      enable = true;
      allowedUDPPorts = [5351 5353];
      allowedTCPPorts = [49152 24800];
    };
  }
