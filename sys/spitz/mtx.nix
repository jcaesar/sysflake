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
  mtxCfg = config.services.matrix-synapse;
in {
  services.matrix-synapse = {
    # manual install/migration steps
    # - import/create db https://nixos.org/manual/nixos/stable/index.html#module-services-matrix-synapse
    # - import media store to /var/lib/matrix-synapse/media_store
    # - import signing key to /var/lib/matrix-synapse/homeserver.signing.key
    # - password pepper?
    # CREATE ROLE "matrix-synapse";
    # GRANT ALL ON DATABASE synapse TO "matrix-synapse";
    # GRANT ALL PRIVILEGES ON ALL {FUNCTIONS,SEQUENCES,TABLES} IN SCHEMA public to "matrix-synapse";
    # alter role "matrix-synapse" login;
    enable = true; # until import
    settings.server_name = fqdn;
    settings.public_baseurl = baseUrl;
    settings.url_preview_enabled = false;
    settings.enable_registration = false;
    settings.federation.client_timeout_ms = 300 * 1000;
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
    settings.turn_uris = ["turn:turn.${fqdn}:3478?transport=udp" "turn:turn.${fqdn}:3478?transport=tcp"];
    settings.turn_user_lifetime = "1h";
    extraConfigFiles = ["${mtxCfg.dataDir}/turn-secret.yaml"]; # contains one line turn_shared_secret: "foobar"
    log.root.level = "WARN";
    log.loggers."synapse.storage.SQL".level = "INFO";
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
