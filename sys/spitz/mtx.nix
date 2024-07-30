{
  pkgs,
  config,
  ...
}: let
  fqdn = "${config.networking.hostName}.${config.networking.domain}";
  baseUrl = "https://${fqdn}";
  clientConfig."m.homeserver".base_url = baseUrl;
  # TODO: blackhole id server
  serverConfig."m.server" = "${fqdn}:443";
  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
in {
  services.matrix-synapse = {
    # manual install/migration steps
    # - import/create db https://nixos.org/manual/nixos/stable/index.html#module-services-matrix-synapse
    # - import media store to /var/lib/matrix-synapse/media_store
    # - import signing key to /var/lib/matrix-synapse/homeserver.signing.key
    enable = false; # until import
    settings.server_name = fqdn;
    settings.public_baseurl = baseUrl;
    settings.listeners = [
      {
        port = 8008;
        bind_addresses = ["::1"];
        type = "http";
        tls = false;
        x_forwarded = true;
        resources = [
          {
            names = ["client" "federation"];
            compress = true;
          }
        ];
      }
    ];
  };

  services.nginx = {
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    virtualHosts = {
      "${fqdn}" = {
        enableACME = true;
        forceSSL = true;
        locations."/".extraConfig = ''
          return 404;
        '';
        locations."/_matrix".proxyPass = "http://[::1]:8008";
        locations."/_synapse/client".proxyPass = "http://[::1]:8008";
        locations."= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
        locations."= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
      };
      "element.${fqdn}" = {
        enableACME = true;
        forceSSL = true;
        serverAliases = [
          "element.${config.networking.domain}"
        ];

        root = pkgs.element-web.override {
          conf.default_server_config = clientConfig;
        };
      };
    };
  };
}
