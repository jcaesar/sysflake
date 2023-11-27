{ config, pkgs, lib, ... }:
let
  shamos = sep: f: lib.strings.concatStringsSep sep (map f [0 1 2 3 4 5 6 7]);
in {
  imports =
    [
      ./hardware-configuration.nix
    ];
  #nix.registry.nixpkgs.flake = nixpkgs;
  #nix.package = pkgs.nixFlakes;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices = { crypt = {
    device = "/dev/disk/by-uuid/4b6c70d3-8d32-4dd1-acfc-ae1b73c67797";
    preLVM = true;
    allowDiscards = false;
  }; }; 

  time.timeZone = "Asia/Tokyo";

  networking.proxy.default = "http://julius9dev9gemini1:7049740682@10.128.145.88:8080/";
  # Escaping fun: If you were to use an email address as user name, nix doesn't quite handle that correctly, and you need to overwrite.
  #systemd.services.nix-daemon.environment =
  #  let p = "http://michaelis%%40jp.fujitsu.com:0123456789@10.128.145.88:8080/";
  #  in lib.mkForce { http_proxy = p; https_proxy = p; all_proxy = p; ftp_proxy = p; };
  networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain,${shamos "," (x: "shamo${toString x}")}";
  networking.interfaces.eth0.ipv4.addresses = [ {
    address = "10.38.90.79";
    prefixLength = 24;
  } ];
  networking.defaultGateway = "10.38.90.1";
  networking.nameservers = [ "10.0.238.70" ];
  networking.hostName = "julius-dev";
  networking.dhcpcd.enable = true;
  networking.extraHosts = shamos "\n" (x: "10.25.211.${toString (84 - x)} shamo${toString x}");

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.julius = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEl5k7aYexi95LNugqwBZQAk/qmA3bruEYqQqFgSpnXSLDeNX0ZZNa8NekuN+Cf7qm9ZJsWZpKzEOi7C//hZa2E= julius@julius"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCFOfuBXwqAurmSh3CsK3JMBWPekby7nOjdcbCtvdp4qwnF3689FKucK4vFIvD+FIqPj2laEe22GSQiFApyg7Aw= julius@PALMAROLA"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBOyNz4Wu9Nl4bwNujJd6lsTZeQd5K+JVi8ZeCDEdxJu2wxjxq1M5miietFH0Dcnz5u+uVEDskyEHMFH1sGkv1BY= julius@PALMAROLA-WSL"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPchDcLGPK3aUz7vVmgjqKNI46NqRn/Q4bszuC/+sFFOaUv4eWzWa4RW6z/UtfO2hPihE5Wj/n3i3jhLz9OiUJk= julius@PALMAROLA"
      "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBABbsQEGFP1kR14NUKW/Rb7OQZjFSy9ibAHReIw6+yAYX8iB0WS+zVQ3CKiuEajxcihu1PSN9h4D702cqBjwTYPMzQH9ptsGCM2xoY9e913rxxj7RgvZho38XeowNFhy0g2ucSi2N2T5rQJXjr9QVVyYdluEh5M8TnZr/11UW7Ro4HSujA== puttygen@PALMAROLA"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNNSNxM0TSVATCXTFinTmy54757P93c7YaesT1X/zIfzar5XwxTj9N0KsjBULgaUChpKKyEvc2DoGdPm2f2/leI= michaelis.g01@ZYPERN"
    ];
    packages = with pkgs; [
      fish nushell helix git gh logcheck
      yaml-language-server java-language-server jdt-language-server dot-language-server docker-compose-language-service cmake-language-server rust-analyzer
    ];
    shell = pkgs.nushell;
    password = "";
  };
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    vim
    wget
    screen
    rxvt-unicode
    lls
    htop
    helix nil
  ];
  #programs.direnv.nix-direnv.enable = true; TODO: IDGI

  services.acpid.enable = true; # 2023-11-17 Might prevent shutdown hang - todo test
  virtualisation.vmware.guest.enable = true;
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


  networking.firewall.allowedTCPPorts = [ 2222 1337 ];
  networking.firewall.allowedUDPPorts = [ ];
  networking.firewall.enable = true;

  #system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  #fileSystems."/boot" =
  #  { device = "/dev/disk/by-label/boot";
  #    fsType = "vfat";
  #  };
}

