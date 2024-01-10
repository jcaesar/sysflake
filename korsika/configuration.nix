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
    ./hardware-configuration.nix
    ./networking.nix
  ];

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
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

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

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    #QT_QPA_PLATFORM = "wayland";
    #CLUTTER_BACKEND = "wayland";
    #SDL_VIDEODRIVER = "wayland";
    #MOZ_ENABLE_WAYLAND = "1";
    #MOZ_WEBRENDER = "1";
    #XDG_SESSION_TYPE = "wayland";
    #XDG_CURRENT_DESKTOP = "sway";
    #QT_QPA_PLATFORMTHEME = "qt5ct";
    #GLFW_IM_MODULE = "fcitx";
    #GTK_IM_MODULE = "fcitx";
    #INPUT_METHOD = "fcitx";
    #XMODIFIERS = "@im=fcitx";
    #IMSETTINGS_MODULE = "fcitx";
    #QT_IM_MODULE = "fcitx";
  };
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-anthy
      fcitx5-gtk
    ];
  };

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

  system.stateVersion = "24.05";
}
