{
  terminalKeys = [
    "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAAqmN0bQWftRFvSCFRmIct6nvwoosuX3hqfp+4uKhUdDxDOThqqqturJUEpovz6Jb/p9nQPee+hMkCMDmpNIEPTKgDaD+MY58tX3bcayHBAoGPyY+RMOaEvHQ+AWjicVqE7Yo9E27sbELIbp0p9QSGDYTaN690ap7KjpoyhlpAvOkV++Q== julius"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNZn3XS8H4UhRKzdCSiVrAPK3JqaNF0LBaA69ozUSLZ6OX6kOGH70NvkgT0okIZZtPi1eqYdBv8lplFOiCEf/8Y= julius@lasta"
  ];
  prideKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAW/KZ2NN0yIz9ppeKb9M4Aks+1N5B617Hl2bHS+lsGVYqIVrFHJ0LNCVfdpR18UliBM3TvQ5FEB17vib3PqzNg= julius@pride";
  wireguardToDoggieworld = {
    listenPort,
    finalOctet,
    privateKeyFile ? "/etc/secrets/wg.pk",
  }: {...}: {
    systemd.network = {
      enable = true;
      netdevs."42-wg-dev" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
          #MTUBytes = "1350";
        };
        wireguardConfig = {
          PrivateKeyFile = privateKeyFile;
          ListenPort = listenPort;
        };
        wireguardPeers = [
          {
            wireguardPeerConfig = {
              PublicKey = "3dY3B1IlbCuBb8FrZ472u+cGXihRGE6+qmo5RZlHdFg=";
              AllowedIPs = ["10.13.38.0/24" "10.13.44.0/24" "fc00:1337:dead:beef:caff::/96"];
              Endpoint = "128.199.185.74:13518";
              PersistentKeepalive = 29;
            };
          }
        ];
      };
      networks."42-wg-net" = {
        matchConfig.Name = "wg0";
        address = [
          "10.13.38.${toString finalOctet}/24"
          "fc00:1337:dead:beef:caff::${toString finalOctet}/96"
        ];
        DHCP = "no";
        networkConfig = {
          IPv6AcceptRA = false;
        };
      };
    };
  };
}
