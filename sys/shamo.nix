shamoIndex: {
  pkgs,
  lib,
  ...
}: let
  common = import ../work.nix;
  shamo = common.shamo;
  kubeMasterIP = shamo.ip 2;
  kubeMasterHostname = shamo.name 2;
  kubeMasterAPIServerPort = 6443;
  proxy = "http://${shamo.internalIp 0}:3128";
in rec {
  imports = lib.optionals (shamoIndex == 4) [
    ./shamo4.nix
  ];
  njx.work = true;
  njx.sysrq = true; # can be fired of from iRMC -> Video Redirection -> Hotkeys
  njx.squid = shamoIndex == 0;

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "nvme" "megaraid_sas" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = ["dm-snapshot"];
  boot.kernelModules = ["kvm-intel"];
  hardware.cpu.intel.updateMicrocode = true;

  njx.sshUnlock.keys = common.sshKeys.strong;
  njx.sshUnlock.modules = ["igb" "i40e"];
  boot.initrd.luks.devices."nixroot".device =
    {
      shamo0 = "/dev/mapper/nvme-nixos";
      shamo2 = "/dev/disk/by-label/nixcrypt";
      shamo4 = "/dev/disk/by-label/nixcrypt";
      shamo6 = "/dev/mapper/nvme-nixos";
      shamo7 = "/dev/mapper/nvme-nixos";
    }
    .${shamo.name shamoIndex};
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };
  fileSystems."/" = {
    device = "/dev/mapper/nixroot";
    fsType = "ext4";
  };

  users.users.root.openssh.authorizedKeys.keys =
    common.sshKeys.strong
    ++ common.sshKeys.k8sconfig
    ++ [common.sshKeys.shamo2];
  programs.ssh.extraConfig = ''
    Host shamo*
      Port 2222
  '';
  networking.proxy.default = proxy;
  systemd.network = {
    enable = true;
    networks."10-fnet" = {
      matchConfig.Name = "eno1";
      DHCP = "no";
      address = ["${shamo.ip shamoIndex}/16"];
      gateway = ["172.16.0.1"];
      dns = ["172.16.150.10" "172.16.150.11"];
      inherit (common) ntp;
    };
    networks."10-rack" = {
      matchConfig.Name = "enp216s0f0";
      DHCP = "no";
      address = ["${shamo.internalIp shamoIndex}/24"];
      routes = shamo.each (x: {
        Destination = "${shamo.ip x}/32";
        Gateway = shamo.internalIp x;
      });
    };
  };
  networking.hostName = shamo.name shamoIndex;

  environment.systemPackages = with pkgs; [kompose kubectl kubernetes logcheck nixpkgs-review nix-output-monitor];

  # Configure client: ssh shamo2 kubectl config view  --flatten | save -f .kube/config
  # Join a node: ssh shamo2 cat /var/lib/kubernetes/secrets/apitoken.secret | ssh shamoX nixos-kubernetes-node-join
  systemd.services.containerd.environment = {
    http_proxy = proxy;
    https_proxy = proxy;
    no_proxy = common.noProxy;
  };
  services.kubernetes = let
    api = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
  in
    {
      masterAddress = kubeMasterHostname;
      easyCerts = true;
      apiserverAddress = api;
      addons.dns.enable = true;
      #addonManager.addons.metrics = lib.importJSON ./k8s-metrics-server.json; # Not possible, the addon manager can't create cluster roles
      kubelet.extraOpts = "--fail-swap-on=false";
    }
    // (
      if shamoIndex == 2
      then {
        roles = ["master" "node"];
        apiserver = {
          securePort = kubeMasterAPIServerPort;
          advertiseAddress = kubeMasterIP;
        };
      }
      else {
        roles = ["node"];
        kubelet.kubeconfig.server = api;
      }
    );
  systemd.services.etcd.serviceConfig.SupplementaryGroups = "kubernetes";
  zramSwap.enable = false; # failed to run Kubelet: running with swap on is not supported

  networking.firewall = let
    inherit (lib.strings) concatStringsSep;
    inherit (lib) concatMap;
    extraRules = sign:
      concatStringsSep "\n" (
        concatMap (port: (map
          (idx: ''
            iptables -${sign} INPUT -p tcp -s ${shamo.ip idx} -m tcp --dport ${toString port} -j ACCEPT
            iptables -${sign} INPUT -p tcp -s ${shamo.internalIp idx} -m tcp --dport ${toString port} -j ACCEPT
          '')
          shamo.nixed))
        [10250 8888 services.prometheus.exporters.node.port 3128]
      )
      + ''
        iptables -${sign} INPUT -p tcp -i mynet -m tcp --dport 3128 -j ACCEPT # shitty name for kube interface
      '';
  in {
    allowedTCPPorts = [2222 1337 6443];
    allowedUDPPorts = [];
    enable = true;
    extraCommands = extraRules "A";
    extraStopCommands = extraRules "D";
  };

  services.prometheus = rec {
    exporters.node = {
      enable = true;
      openFirewall = true;
      port = 9100;
      njx.powercap = true;
    };
    port = 9090;
    enable = shamoIndex == 2;
    globalConfig = {
      scrape_interval = "5s";
      evaluation_interval = "5s";
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
            targets = map (idx: "${shamo.name idx}:${toString exporters.node.port}") shamo.nixed;
          }
        ];
      }
    ];
  };

  # https://nixos.wiki/wiki/Storage_optimization#Automation
  nix.optimise = {
    automatic = true;
    dates = ["*-*-* 18:45 UTC"];
  };
  nix.extraOptions = let
    gb = x: toString (x * 1024 * 1024 * 1024);
  in ''
    min-free = ${gb 3}
    max-free = ${gb 20}
  '';
  systemd.services.njx-delete-generations.serviceConfig.ExecStart = "${lib.getExe' pkgs.njx "njx-delete-generations"} fmuf";
  systemd.timers.njx-delete-generations = {
    timerConfig.OnBootSec = "6 days";
    wantedBy = ["timers.target"];
  };

  services.vector = {
    enable = true;
    package = pkgs.vector-cloudwatchsyslogs;
    journaldAccess = true;
    settings = {
      sources.journal.type = "journald";
      sinks.cw = {
        type = "aws_cloudwatch_logs";
        inputs = ["journal"];
        group_name = "/fnet/shamo/syslog";
        stream_name = "{{ host }}";
        encoding.codec = "json";
        region = "ap-northeast-1";
        auth.credentials_file = "/run/credentials/vector.service/cloudwatch"; # I'd prefer to use "\${CREDENTIALS_DIRECTORY}/cloudwatch", but that fails the verify check
        batch.timeout_secs = 10;
        create_missing_group = true;
        create_missing_stream = true;
        proxy.enabled = true;
        proxy.https = proxy;
      };
    };
  };
  systemd.services.vector = {
    serviceConfig.LoadCredential = "cloudwatch:/etc/secrets/cloudwatch";
    environment.VECTOR_LOG = "warn"; # It'll log "Putting events successfull" to the syslog, and then try to log that. Indefinitely.
  };
  njx.manual.vector-aws-cloudwatch = ''
    1. Create access
       ```
       aws iam create-user --user-name shamo-log-appender
       aws iam attach-user-policy --user-name shamo-log-appender --policy-arn arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs
       aws iam create-access-key --user-name shamo-log-appender
       ```
    2. Create credential file at `/etc/secrets/cloudwatch`
       ```
       touch /etc/secrets/cloudwatch
       chmod 400 /etc/secrets/cloudwatch
       ```
       ```
       [default]
       aws_access_key_id = (output from create-access-key)
       aws_secret_access_key = (output from create-access-key)
       ```
    3. After vector's first run, fix log retention policy
       ```
       aws logs put-retention-policy --log-group-name /fnet/shamo/syslog --retention-in-days 30
       ```
       (Vector itself has functionality for that, but it requires allowing changing the retention policy, including shortening it unreasonably)
  '';

  system.stateVersion = "23.05";
}
