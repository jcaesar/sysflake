# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
  ];
  njx.common = true;
  njx.graphical = true;
  njx.binfmt = true;
  njx.work = true;

  boot.kernelModules = [
    "akvcam"
    "v4l2loopback"
  ];
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 card_label="Software"
  '';
  boot.initrd.services.resolved.enable = lib.mkForce false; # if I don't, I get an error complaining that this only works with systemd stage 1. Oo

  networking.hostName = "korsika";
  virtualisation.docker.rootless.daemon.settings.dns = ["9.9.9.9" "1.1.1.1"];

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
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        rofi
        alacritty
        rxvt-unicode
        i3status
        i3lock
        x11vnc
        xdotool
      ];
    };
  };
  services.displayManager.defaultSession = "none+i3";

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  nixpkgs.config.allowUnfreePredicate = let
    startsWith = pfx: str: lib.removePrefix pfx str != str;
  in
    pkg: startsWith "nvidia-" (lib.getName pkg);
  services.xserver.videoDrivers = ["nvidia"];

  services.ddccontrol.enable = true;

  # nix shell --print-build-logs .#nixosConfigurations.korsika.config.system.build.vm -c run-korsika-vm
  # Switch to serial0 console from qemu viewer
  services.getty.autologinUser =
    if config.virtualisation ? mountHostNixStore
    then "root"
    else lib.mkDefault null;
  #system.copySystemConfiguration = true;

  environment.systemPackages = with pkgs; [
    ipmitool
  ];
  users.users.julius.packages = with pkgs; [
    awscli
    k9s
    kubectl
    eksctl
    jetbrains.idea-community
    openjdk11
    kcat
    duckdb
    freerdp3
    simplescreenrecorder
    ffmpeg
    piper-tts
    barrier
  ];
  home-manager.users.julius.programs.git.extraConfig."url \"github.com:fltech-dev/\"".insteadOf = "https://github.com/fltech-dev/";
  users.users.julius.openssh.authorizedKeys.keys = (import ../../work.nix).sshKeys.client;

  networking.extraHosts = ''
    0.0.0.0 blog.fefe.de
    0.0.0.0 news.ycombinator.com
    0.0.0.0 pr0gramm.com # never actually opened
  '';

  system.stateVersion = "24.05";
}
