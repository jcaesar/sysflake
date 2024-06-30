# small gateway for korsika
let
  common =
    import ../work.nix;
in
  {lib, ...}: {
    njx.work = true;

    networking.hostName = "gozo";

    boot.initrd.systemd.enable = true;
    virtualisation.docker = {
      enable = lib.mkForce false;
      rootless.enable = lib.mkForce false;
    };
    virtualisation.virtualbox.guest.enable = true;
    users.users.root.openssh.authorizedKeys.keys = common.sshKeys.strong;
    services.smartd.enable = false;

    # Too little ram for nix run nixpkgs#… anyway
    nixpkgs.flake = {
      setNixPath = false;
      setFlakeRegistry = false;
    };

    services.resolved.extraConfig = ''
      FallbackDNS=
      DNSStubListener=no
      DNSStubListenerExtra=10.13.26.1:5353
    '';
    networking.firewall.allowedUDPPorts = [5353];

    systemd.network = {
      enable = true;
      networks."10-uplink" = {
        matchConfig.Name = "enp0s3";
        DHCP = "yes";
      };
      networks."10-korsikalink" = {
        matchConfig.Name = "enp0s9";
        DHCP = "no";
        address = ["10.13.25.1/24"];
      };
      netdevs."20-korsikawg" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg";
          MTUBytes = "1350";
        };
        wireguardConfig = {
          PrivateKeyFile = "/etc/secrets/gozo.pk";
          ListenPort = 53;
        };
        wireguardPeers = [
          {
            # korsika
            wireguardPeerConfig = {
              PublicKey = "I7MQODJwrZHVmAQsXZUsyxdi8hfDpMbPWKGk6TnElxM=";
              Endpoint = "10.13.25.2:36749";
              AllowedIPs = ["10.13.26.2/32"];
              PersistentKeepalive = 29;
            };
            # forgot what these were
            # [WireGuardPeer]
            # PublicKey=4qitTsPLqLKmFOxRgqhSHDVzmyCeWWuTE2+ygZI7/lU=
            # AllowedIPs=10.13.26.3/32
            # Endpoint=10.0.2.2:36779
            # [WireGuardPeer]
            # PublicKey=AB4SZI/4kUIe/bbgN7Wy1DxP1I/GGjheeBRF7A+hozs=
            # AllowedIPs=10.13.26.4/32
            # Endpoint=10.13.25.4:36778
          }
        ];
      };
      networks."20-korsikawg" = {
        matchConfig.Name = "wg";
        address = ["10.13.26.1/24"];
        DHCP = "no";
      };
    };

    networking.nat.enable = true;
    networking.nat.internalInterfaces = ["wg"];
    networking.nat.externalInterface = "enp0s3";

    # TODO: factor out into module?
    disko.devices.disk.diks = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
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
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };

    system.stateVersion = "24.05";
  }
