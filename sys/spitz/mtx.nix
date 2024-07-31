{
  pkgs,
  config,
  ...
}: let
  fqdn = "mtx.liftm.de";
  baseUrl = "https://${fqdn}";
  clientConfig."m.homeserver".base_url = baseUrl;
  clientConfig."m.identity_server".base_url = "https://blackhole.liftm.de";
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
    # - password pepper
    enable = true; # until import
    settings.server_name = fqdn;
    settings.public_baseurl = baseUrl;
    settings.url_preview_enabled = false;
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
    settings.database.args.database = "synapse";
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
      "riot.${config.networking.domain}" = {
        enableACME = true;
        forceSSL = true;
        root = pkgs.element-web.override {
          conf.default_server_config = clientConfig;
        };
      };
    };
  };
}
