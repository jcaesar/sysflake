shamoIndex: { pkgs, lib, ... }:

let
  common = import ../common.nix;
  inherit  (lib.strings) concatStringsSep;
  inherit (lib) concatMap;
  shamo = common.shamo;
  kubeMasterIP = shamo.ip 2;
  kubeMasterHostname = shamo.name 2;
  kubeMasterAPIServerPort = 6443;
  proxy = common.proxy "shamo09stratus9flab" "9491387463";
in
{
  imports = [
    ./hardware-shamo${toString shamoIndex}.nix
    common.config
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.initrd.luks.devices."crypt".preLVM = false;
  users.users.root.openssh.authorizedKeys.keys = [
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEl5k7aYexi95LNugqwBZQAk/qmA3bruEYqQqFgSpnXSLDeNX0ZZNa8NekuN+Cf7qm9ZJsWZpKzEOi7C//hZa2E= julius@julius"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLN6IOSFfpYCNhM/Qzj02GdHIblSsvV2LtgTUSawvZNapLxdCThhn6BD863/960MOnUThW9IyXf4jmX4eVzyqFI= root@shamo2"
  ];
  programs.ssh.extraConfig = ''
    Host shamo*
      Port 2222
  '';
  networking.proxy.default = proxy;
  networking.proxy.noProxy = common.noProxy;
  networking.interfaces.eno1.ipv4.addresses = [{
    address = shamo.ip shamoIndex;
    prefixLength = 24;
  }];
  networking.interfaces.enp216s0f0.ipv4 = {
    addresses = [{
      address = "192.168.100.${toString (shamoIndex + 2)}";
      prefixLength = 24;
    }];
    routes = shamo.each (x: {
      prefixLength = 32;
      address = shamo.ip x;
      via = "192.168.100." + toString (x + 2);
    });
  };
  networking.defaultGateway = "10.25.211.1";
  networking.hostName = shamo.name shamoIndex;
  networking.dhcpcd.enable = false;

  environment.systemPackages = with pkgs; [ kompose kubectl kubernetes ] ++ common.packages pkgs;

  systemd.services.containerd.environment = { http_proxy = proxy; https_proxy = proxy; no_proxy = common.noProxy; };
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
      iptables -${sign} INPUT -p tcp -s ${shamo.ip idx} -m tcp --dport ${toString port} -j ACCEPT
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
}

