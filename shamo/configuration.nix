shamoIndex: {
  pkgs,
  lib,
  modulesPath,
  config,
  ...
}: let
  common = import ../work.nix;
  shamo = common.shamo;
  kubeMasterIP = shamo.ip 2;
  kubeMasterHostname = shamo.name 2;
  kubeMasterAPIServerPort = 6443;
  proxy = common.proxy "shamo09stratus9flab" "9491387463";
in {
  imports = [
    ../base.nix
    common.fnet
  ]
   ++ (if shamoIndex == 0 then ["${modulesPath}/installer/netboot/netboot-minimal.nix"] else [])
  ;


  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform = "x86_64-linux";
  boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "nvme" "megaraid_sas" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = ["dm-snapshot"];
  boot.kernelModules = ["kvm-intel"];

  boot.initrd.luks.devices."nixroot".preLVM = false;
  boot.initrd.luks.devices."nixroot".device = {
    shamo0 = "/dev/mapper/nvme-nixos";
    shamo2 = "/dev/disk/by-label/nixcrypt";
    shamo6 = "/dev/mapper/nvme-nixos";
    shamo7 = "/dev/mapper/nvme-nixos";
  }.${shamo.name shamoIndex};
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
  networking.interfaces.eno1.ipv4.addresses = [
    {
      address = shamo.ip shamoIndex;
      prefixLength = 24;
    }
  ];
  networking.interfaces.enp216s0f0.ipv4 = {
    addresses = [
      {
        address = shamo.internalIp shamoIndex;
        prefixLength = 24;
      }
    ];
    routes = shamo.each (x: {
      prefixLength = 32;
      address = shamo.ip x;
      via = shamo.internalIp x;
    });
  };
  networking.defaultGateway = {
    address = "10.25.211.1";
    interface = "eno1";
  };
  networking.hostName = shamo.name shamoIndex;
  networking.dhcpcd.enable = false;

  environment.systemPackages = with pkgs; [kompose kubectl kubernetes] ++ common.packages pkgs;

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

  networking.firewall = let
    inherit (lib.strings) concatStringsSep;
    inherit (lib) concatMap;
    extraRules = sign:
      concatStringsSep "\n" (concatMap
        (port: (map
            (idx: "
      iptables -${sign} INPUT -p tcp -s ${shamo.ip idx} -m tcp --dport ${toString port} -j ACCEPT
      iptables -${sign} INPUT -p tcp -s ${shamo.internalIp idx} -m tcp --dport ${toString port} -j ACCEPT
    ") [2 6 7])) [10250 8888]);
  in {
    allowedTCPPorts = [2222 1337 6443];
    allowedUDPPorts = [];
    enable = true;
    extraCommands = extraRules "A";
    extraStopCommands = extraRules "D";
  };

  system.stateVersion = "23.05";
}
