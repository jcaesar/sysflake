shamoIndex: { pkgs, lib, ... }:

let
  concatStringsSep = lib.strings.concatStringsSep;
  concatMap = lib.concatMap;
  shamoF = f: map f [ 0 1 2 3 4 5 6 7 ];
  shamoIp = x: "10.25.211." + toString (84 - x);
  shamoName = x: "shamo" + toString x;
in
let
  hostname = shamoName shamoIndex;
  kubeMasterIP = shamoIp 2;
  kubeMasterHostname = "shamo2";
  kubeMasterAPIServerPort = 6443;
  proxy = "http://shamo09stratus9flab:9491387463@10.128.145.88:8080/";
  no_proxy = "127.0.0.1,localhost,fujitsu.co.jp," + concatStringsSep "," (shamoF shamoName);
in
{
  imports = [ ./hardware-shamo${toString shamoIndex}.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.initrd.luks.devices."crypt".preLVM = false;
  users.users.root.openssh.authorizedKeys.keys = [
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEl5k7aYexi95LNugqwBZQAk/qmA3bruEYqQqFgSpnXSLDeNX0ZZNa8NekuN+Cf7qm9ZJsWZpKzEOi7C//hZa2E= julius@julius"
  ];
  networking.proxy.default = proxy;
  networking.proxy.noProxy = no_proxy;
  networking.interfaces.eno1.ipv4.addresses = [{
    address = shamoIp shamoIndex;
    prefixLength = 24;
  }];
  networking.interfaces.enp216s0f0.ipv4 = {
    addresses = [{
      address = "192.168.100.${toString (shamoIndex + 2)}";
      prefixLength = 24;
    }];
    routes = shamoF (x: {
      prefixLength = 32;
      address = shamoIp x;
      via = "192.168.0." + toString (x + 2);
    });
  };
  networking.defaultGateway = "10.25.211.1";
  networking.nameservers = [ "10.0.238.1" ];
  networking.hostName = hostname;
  networking.dhcpcd.enable = false;
  networking.extraHosts = concatStringsSep "\n" (shamoF (x: "${shamoIp x} shamo${toString x}"));

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    vim
    wget
    screen
    rxvt-unicode
    lls
    helix
    nil
    htop
    kompose
    kubectl
    kubernetes
  ];

  systemd.services.containerd.environment = { http_proxy = proxy; https_proxy = proxy; no_proxy = no_proxy; };
  services.kubernetes =
    let
      api = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
    in
    {
      masterAddress = kubeMasterHostname;
      easyCerts = true;
      apiserverAddress = api;
      addons.dns.enable = true;
      #addonManager.addons.metrics = lib.importJSON ./k8s-metrics-server.json; # Not possible, the addon manager can't create cluster roles
      kubelet.extraOpts = "--fail-swap-on=false";
    } // (if shamoIndex == 2 then {
      roles = [ "master" "node" ];
      apiserver = {
        securePort = kubeMasterAPIServerPort;
        advertiseAddress = kubeMasterIP;
      };
    } else {
      roles = [ "node" ];
      kubelet.kubeconfig.server = api;
    });
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "prohibit-password";
    settings.ListenAddress = "0.0.0.0:2222";
  };
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  networking.firewall =
    let
      extraRules = (sign: concatStringsSep "\n" (concatMap
        (port: (map
          (idx: "
      iptables -${sign} INPUT -p tcp -s ${shamoIp idx} -m tcp --dport ${toString port} -j ACCEPT
    ") [ 2 6 7 ])) [ 10250 8888 ]));
    in
    {
      allowedTCPPorts = [ 2222 1337 6443 ];
      allowedUDPPorts = [ ];
      enable = true;
      extraCommands = extraRules "A";
      extraStopCommands = extraRules "D";
    };

  system.stateVersion = "23.05";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}

