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
    ../common.nix
    ../graphical.nix
    (import ../work.nix).config
    ./hardware-configuration.nix
    ./networking.nix
  ];

  boot.kernelModules = [
    "akvcam"
    "v4l2loopback"
  ];
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 card_label="Software"
  '';

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
        x11vnc
      ];
    };
  };

  programs.command-not-found.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false; # I wish
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
    else null;
  #system.copySystemConfiguration = true;

  environment.systemPackages = with pkgs; [
    ipmitool
    awscli
  ];
  users.users.julius.packages = with pkgs; [
    k9s
    kubectl
    jetbrains.idea-community
    openjdk11
    kcat
  ];

  system.stateVersion = "24.05";
}
