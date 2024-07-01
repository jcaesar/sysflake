{
  config,
  lib,
  ...
}: let
  key = "wireguardToDoggieworld";
  cfg = config.njx.${key};
in {
  options.njx.${key} = {
    enable = lib.mkEnableOption "10.13.38.";
    finalOctet = lib.mkOption {
      type = with lib.types; nullOr number;
      default = null;
    };
    listenPort = lib.mkOption {
      type = with lib.types; nullOr number;
      default = null;
    };
    privateKeyFile = lib.mkOption {
      type = lib.types.path;
      default = "/etc/secrets/wg.pk";
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.network = {
      enable = true;
      netdevs."42-wg-dev" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
          #MTUBytes = "1350";
        };
        wireguardConfig = {
          PrivateKeyFile = cfg.privateKeyFile;
          ListenPort = cfg.listenPort;
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
          "10.13.38.${toString cfg.finalOctet}/24"
          "fc00:1337:dead:beef:caff::${toString cfg.finalOctet}/96"
        ];
        DHCP = "no";
        networkConfig = {
          IPv6AcceptRA = false;
        };
      };
    };
  };
}
