{config, ...}: let
  aws_sink = {
    type = "aws_cloudwatch_logs";
    encoding.codec = "json";
    region = "ap-northeast-1";
    auth.credentials_file = "/run/credentials/vector.service/cloudwatch";
    batch.timeout_secs = 10;
    create_missing_group = true;
    create_missing_stream = true;
    proxy.enabled = true;
    proxy.https = config.networking.proxy.default;
  };
in {
  services.vector = {
    enable = true;
    journaldAccess = true;
    settings = {
      sources.gemini4syslog = {
        type = "syslog";
        address = "0.0.0.0:1514";
        mode = "tcp";
      };
      sinks.gemini4syslogsink =
        aws_sink
        // {
          inputs = ["gemini4syslog"];
          group_name = "/fnet/gemini/syslog";
          stream_name = "gemini4"; # TODO get smarter if we get more vmwares
        };
      sources.journal.type = "journald";
      sinks.journalsink =
        aws_sink
        // {
          inputs = ["journal"];
          group_name = "/fnet/gemini/syslog";
          stream_name = "{{ host }}";
        };
    };
  };
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -i ens32 -s 10.38.90.52 -p tcp -m tcp --dport 1514 \
      -m comment --comment gemini4syslog -j nixos-fw-accept
  '';
  systemd.services.vector = {
    serviceConfig.LoadCredential = "cloudwatch:/etc/secrets/cloudwatch";
    environment.VECTOR_LOG = "warn";
  };
  njx.manual.vector = ''
    Basic setup: Check shamo

    VMware:
    ```
    esxcli network firewall ruleset set -e true -r syslog
    esxcli system syslog config set --loghost $ip:1514
    esxcli system syslog reload # <- If something's stuck
    ```
  '';
}
