{...}: {
  networking.domain = "liftm.de";
  systemd.network = {
    enable = true;
    networks."10-eth0" = {
      matchConfig.Name = "eth0";
      DHCP = "no";
      address = ["128.199.185.74/18" "10.15.0.5/16" "2400:6180:0:d0::241:9001/64" "fe80::acbe:d1ff:fe8d:175b/64"];
      gateway = ["28.199.128.1" "2400:6180:0:d0::1"];
      dns = ["2001:4860:4860::8844" "2001:4860:4860::8888" "209.244.0.3" "8.8.4.4"];
    };
    #netdevs."11-wg" = {
    #  netdevConfig = {
    #    Kind = "wireguard";
    #    Name = "wg";
    #  };
    #  wireguardConfig = {
    #    PrivateKeyFile = "/etc/secrets/gozo.pk";
    #    ListenPort = 36749;
    #  };
    #  wireguardPeers = [
    #    {
    #        PublicKey = "BThC89DqFj+nGtkCytNSskolwCijeyq/XDiAM8hQJRw=";
    #        Endpoint = "10.13.25.1:53";
    #        AllowedIPs = ["0.0.0.0/0"];
    #        PersistentKeepalive = 29;
    #    }
    #  ];
    #};
    networks."11-wg" = {
      matchConfig.Name = "gozo";
      address = ["fc00:1337:dead:beef:caff::1/96" "10.13.38.1/24" "10.13.44.1/24"];
      DHCP = "no";
      networkConfig = {
        IPv6AcceptRA = false;
      };
    };
  };
  networking.extraHosts = ''
    10.13.38.6 akachan.liftm
    10.13.38.8 pride.liftm
    10.13.38.9 services.akachan.liftm
    10.13.44.190 liftm
    10.13.55.2 papache
    127.91.0.0 doggieworld.liftm
    2a02:7b40:50d0:e6d0::1 genone.liftm
    fcae:eb4c:4d71:96cb:f5af:7671:c5b2:c6b5 cameo.liftm
    #fcb2:8f56:a02f:7df6:c1b5:23d4:18a0:cca8 services.akachan.liftm
    #fcb4:3065:3d0b:513d:7558:68f8:42d:304e papache
    #fcec:ae97:8902:d810:6c92:ec67:efb2:3ec5 irc-fc00-io
    #fcff:b419:23a9:cd5b:5b76:e9e8:4fa7:4f5 pride.liftm
  '';
}
