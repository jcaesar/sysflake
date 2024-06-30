{
  lib,
  pkgs,
  ...
}: {
  njx.common = true;
  njx.graphical = true;
  njx.dlna = true;
  njx.bluetooth = true;

  networking.hostName = "lasta";

  boot.loader.systemd-boot.editor = lib.mkForce true;
  boot.supportedFilesystems = ["bcachefs"];
  boot.initrd.availableKernelModules = import ./bootmods.nix;
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.initrd.systemd.enable = true;
  hardware.cpu.intel.updateMicrocode = true;

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

  services.openssh.enable = true;

  services.xserver.enable = true;
  home-manager.users.julius.wayland.windowManager.hyprland.enable = true;
  programs.command-not-found.enable = true;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  users.users.julius.packages = with pkgs; [
    element-desktop-wayland
    pyanidb
    (himalaya.override {buildFeatures = ["notmuch"];})
    notmuch
    nextcloud-client
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

  system.stateVersion = "24.05";
}
