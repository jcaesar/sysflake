{
  config,
  lib,
  pkgs,
  pkgsStable,
  modulesPath,
  ...
}: let
  private = import ./private.nix;
in {
  imports = [
    ./common.nix
    ./graphical.nix
    ./dlna.nix
    (modulesPath + "/installer/scan/not-detected.nix")
    (import ./ssh-unlock.nix {
      authorizedKeys = private.terminalKeys;
      extraModules = ["e1000e"];
    })
  ];

  networking.hostName = "lasta";

  boot.loader.systemd-boot.editor = lib.mkForce true;
  boot.supportedFilesystems = ["bcachefs"];
  boot.initrd.availableKernelModules = import ./lasta-allmods.nix;
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.initrd.systemd.enable = true;
  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/primary";
    fsType = "bcachefs";
    options = ["compression=zstd"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/ESP";
    fsType = "vfat";
  };

  networking.supplicant.wlp2s0.configFile.writable = true;
  networking.supplicant.wlp2s0.configFile.path = "/etc/wpa_supplicant.conf";
  networking.wireless.userControlled.enable = true;
  systemd.network = {
    enable = true;
    networks."12-wifi-dhcp-required" = {
      matchConfig.Name = ["wlp2s0"];
      DHCP = "yes";
    };
    networks."12-wired-dhcp-optional" = {
      matchConfig.Name = ["enp0s31f6"];
      linkConfig.RequiredForOnline = false;
      DHCP = "yes";
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;
  home-manager.users.julius = {...}: {
    systemd.user.services.mpris-proxy = {
      Unit.Description = "Mpris proxy";
      Unit.After = ["network.target" "sound.target"];
      Unit.WantedBy = ["default.target"];
      Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    };
  };

  services.openssh.enable = true;

  services.xserver = {
    enable = true;
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

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  programs.command-not-found.enable = true;

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  users.users.julius.packages = with pkgs; [
    element-desktop-wayland
    (pkgsStable.himalaya.override {withNotmuchBackend = true;})
    notmuch
  ];

  services.nzbget = {
    enable = true;
    settings.MainDir = "/home/julius/nz";
    user = "julius";
    group = "users";
  };
  services.minidlna = {
    enable = true;
    openFirewall = true;
    settings = {
      inotify = "yes";
      media_dir = [
        "V,/home/julius/nz/dst/"
        "V,/home/julius/anime/"
      ];
    };
  };
  systemd.services.minidlna.serviceConfig.SupplementaryGroups = "users";
  nixpkgs.config.allowUnfreePredicate = pkg:
    (
      name: (builtins.elem name [
        "unrar"
      ])
    ) (lib.getName pkg);

  networking.extraHosts = ''
    0.0.0.0 pr0gramm.com
  '';

  system.stateVersion = "24.05";
}
