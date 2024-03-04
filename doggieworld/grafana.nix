let
  http_addr = "127.0.0.1";
  http_port = 3000;
  domain = "grafana.liftm.de";
in
  {...}: {
    services.nginx = {
      enable = true;
    };
  
    services.nginx.virtualHosts.${domain} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://${http_addr}:${toString http_port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
        basicAuthFile = "/etc/secrets/grafana.htpasswd"; # users: admin julius dit
      };
    };

    services.grafana = {
      enable = true;
      settings = {
        server = {
          inherit http_addr http_port domain;
        };
      };
    };
  }
