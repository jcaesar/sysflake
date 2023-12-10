# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot = {
  	enable = true;
  	configurationLimit = 15;
  	editor = false;
    };
    efi.canTouchEfiVariables = true;
  };
  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "en_US.UTF-8";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  networking.firewall.enable = true;
  #security.sudo.wheelNeedsPassword = false;
  networking.nameservers = [ "10.0.238.1" "10.0.238.70" ];
  networking.useNetworkd = true;
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

  networking.hostName = "korsika";

  services.xserver.enable = true;
  #services.xserver.xkbd = {
  #  layout = "us";
  #  options = "compose:caps";
  #  variant = "altgr-intl";
  #};

  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    #jack.enable = true;
  };

  users.users.julius = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    #openssh.authorizedKeys.keys = common.sshKeys.client;
    packages = with pkgs; [
      fish
      nushell
      helix
      git
      gh
    ];
    shell = pkgs.nushell;
    password = "";
  };

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget

    vim
    helix
    nil
    pv
    jq
    rq
    wget
    httpie
    git
    screen
    tmux
    rxvt-unicode
    lls
    htop
    bottom
    iotop
    logcheck
    direnv
  ];

  networking.wireguard.interfaces = {
    gozo = {
      ips = [ "10.13.26.2/24" ];
      privateKeyFile = "/etc/secrets/gozo.pk";
      listenPort = 36749;
      peers = [
        {
          allowedIPs = [ "0.0.0.0/24" ];
          publicKey = "BThC89DqFj+nGtkCytNSskolwCijeyq/XDiAM8hQJRw=";
          endpoint = "10.13.25.1:53";
          persistentKeepalive = 29; 
        }
      ];
    };
  };
  
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "10.13.25.2";
    prefixLength = 24;
  }];
  #system.copySystemConfiguration = true;

  system.stateVersion = "24.05";

}

