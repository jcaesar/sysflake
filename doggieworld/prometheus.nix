let
  mkInstanceLabel = {
    source_labels = ["__address__"];
    regex = "([^:]+):\d+";
    target_label = "instance";
  };
  port = 9090;
in
  {...}: {
    services.prometheus = {
      inherit port;
      enable = true;
      globalConfig = {
        scrape_interval = "15s";
        evaluation_interval = "15s";
      };
      scrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = [
            {
              targets = ["localhost:${toString port}"];
            }
          ];
        }
        {
          job_name = "node";
          static_configs = [
            {
              targets = [
                "doggieworld.liftm:9100"
                "liftm:9100"
                "services.akachan.liftm:9100"
                "akachan.liftm:9100"
                "cameo.liftm.de:80"
                "pride.liftm:9100"
              ];
            }
          ];
          relabel_configs = [mkInstanceLabel];
        }
        {
          job_name = "synapse";
          metrics_path = "/_metrics/synapse/";
          static_configs = [
            {
              targets = ["services.akachan.liftm:9102"];
            }
          ];
          scrape_interval = "180s";
        }
        {
          job_name = "akachan_pg";
          metrics_path = "/_metrics/pg/";
          static_configs = [
            {
              targets = ["services.akachan.liftm:9102"];
            }
          ];
          scrape_interval = "60s";
        }
        {
          job_name = "nvml";
          metrics_path = "/metrics";
          static_configs = [
            {
              targets = ["pride.liftm:9144"];
            }
          ];
          relabel_configs = [mkInstanceLabel];
        }
        #{
        #  job_name = "cgroups";
        #  metrics_path = "/metrics";
        #  static_configs = [{
        #    targets = ["services.akachan.liftm:9104" "akachan.liftm:9134"];
        #  }];
        #  relabel_configsi = [mkInstanceLabel];
        #}
      ];
    };
    services.prometheus.exporters.node.enable = true;
  }
