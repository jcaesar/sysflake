shamoIndex: {
  pkgs,
  lib,
  modulesPath,
  config,
  ...
}: let
  common = import ./work.nix;
  shamo = common.shamo;
  kubeMasterIP = shamo.ip 2;
  kubeMasterHostname = shamo.name 2;
  kubeMasterAPIServerPort = 6443;
  proxy = common.proxy "shamo09stratus9flab" "9491387463";
in rec {
  imports = [
    ./base.nix
    common.config
    (import ./ssh-unlock.nix {
      authorizedKeys = common.sshKeys.strong;
      extraModules = ["igb" "i40e"];
    })
    (
      if shamoIndex == 4
      then ./shamo4.nix
      else ({...}: {})
    )
  ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform = "x86_64-linux";
  boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "nvme" "megaraid_sas" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = ["dm-snapshot"];
  boot.kernelModules = ["kvm-intel"];

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
    ++ [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLN6IOSFfpYCNhM/Qzj02GdHIblSsvV2LtgTUSawvZNapLxdCThhn6BD863/960MOnUThW9IyXf4jmX4eVzyqFI= root@shamo2"
    ];
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
      address = ["${shamo.ip shamoIndex}/24"];
      gateway = ["10.25.211.1"];
      inherit (common) dns ntp;
    };
    networks."10-rack" = {
      matchConfig.Name = "enp216s0f0";
      DHCP = "no";
      address = ["${shamo.internalIp shamoIndex}/24"];
      routes = shamo.each (x: {
        routeConfig = {
          Destination = "${shamo.ip x}/32";
          Gateway = shamo.internalIp x;
        };
      });
    };
  };
  networking.hostName = shamo.name shamoIndex;
  networking.useDHCP = false;

  environment.systemPackages = with pkgs; [kompose kubectl kubernetes] ++ common.packages pkgs;

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
        [10250 8888 services.prometheus.exporters.node.port]
      );
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

  system.stateVersion = "23.05";
}
