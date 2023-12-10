# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./networking.nix
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

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      options = "compose:caps";
      variant = "altgr-intl";
    };
    desktopManager = {
      xterm.enable = false;
    };
    displayManager = {
      defaultSession = "none+i3";
    };
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        rofi
        alacritty
        rxvt-unicode
        i3status
        i3lock
      ];
    };
  };
  environment.etc."xsg/user-dirs.defaults".text = ''
    XDG_DESKTOP_DIR="$HOME/desktop"
    XDG_DOWNLOAD_DIR="$HOME/downloads"
    XDG_TEMPLATES_DIR="$HOME/.config/templates"
    XDG_PUBLICSHARE_DIR="$HOME/public"
    XDG_DOCUMENTS_DIR="$HOME/docs"
    XDG_MUSIC_DIR="$HOME/music"
    XDG_PICTURES_DIR="$HOME/music"
    XDG_VIDEOS_DIR="$HOME/music"
  '';
  environment.variables.EDITOR = "hx";

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
      firefox
    ];
    shell = pkgs.nushell;
    password = "";
  };

  environment.systemPackages = with pkgs; [
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
    lls
    htop
    bottom
    iotop
    logcheck
    direnv
    nload
    ripgrep
  ];

  #system.copySystemConfiguration = true;

  system.stateVersion = "24.05";
}
