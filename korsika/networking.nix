let
  palmarolaPort = "enp0s31f6";
  cameoPort = "enp2s0";
in
  {
    config,
    pkgs,
    ...
  }: {
    networking.useDHCP = false;
    #boot.extraModulePackages = [config.boot.kernelPackages.wireguard];
    systemd.network = {
      enable = true;
      networks."10-palmarola-eth-net" = {
        matchConfig.Name = palmarolaPort;
        DHCP = "no";
        address = ["10.13.25.2/24"];
      };
      netdevs.      "11-palmarola-wg-dev" = {
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
            wireguardPeerConfig = {
              PublicKey = "BThC89DqFj+nGtkCytNSskolwCijeyq/XDiAM8hQJRw=";
              Endpoint = "10.13.25.1:53";
              AllowedIPs = ["0.0.0.0/0"];
              PersistentKeepalive = 29;
            };
          }
        ];
      };
      networks."11-palmarola-wg-net" = {
        matchConfig.Name = "gozo";
        address = ["10.13.26.2/24"];
        DHCP = "no";
        dns = ["10.9.70.1 10.10.10.1"];
        ntp = [];
        gateway = [
          "10.13.26.1"
        ];
        networkConfig = {
          IPv6AcceptRA = false;
        };
      };
    };

    systemd.network.networks."10-cameo" = {
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
      interfaces.${palmarolaPort}.allowedTCPPorts = [24800]; # barrier server
    };
  }