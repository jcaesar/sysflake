{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  private = import ../private.nix;
in {
  imports = [
    ../mod/common.nix
    ../mod/graphical.nix
    ../mod/dlna.nix
    ../mod/bluetooth.nix
    (modulesPath + "/installer/scan/not-detected.nix")
    (private.wireguardToDoggieworld {
      listenPort = 51820;
      finalOctet = 2;
      privateKeyFile = "/etc/secret-wg-private.key";
    })
  ];

  networking.hostName = "mictop";

  boot.initrd.availableKernelModules = ["xhci_pci" "ehci_pci" "ahci" "usb_storage" "sd_mod" "rtsx_pci_sdmmc"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];

  boot.initrd.luks.devices."nixcrypt".device = "/dev/disk/by-uuid/09e5a891-b57f-4068-9332-5ce8c4dad926";
  boot.initrd.luks.devices."oldroot".device = "/dev/disk/by-uuid/11854422-4b07-4081-a5cf-393f4060b933";
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/74aa08e1-6c0a-42aa-8fb2-78826dc4f1e9";
    fsType = "f2fs";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C7DE-A7CE";
    fsType = "vfat";
  };
  fileSystems."/mnt/oldroot" = {
    device = "/dev/disk/by-uuid/e11c57ad-ed99-45b9-82cf-b7addcf00304";
    fsType = "ext4";
  };
  fileSystems."/home/julius" = {
    device = "/mnt/oldroot/home/julius";
    fsType = "none";
    options = ["bind"];
  };

  networking.supplicant.wlp3s0.configFile.writable = true;
  networking.supplicant.wlp3s0.configFile.path = "/etc/wpa_supplicant.conf";
  networking.wireless.userControlled.enable = true;
  systemd.network = {
    enable = true;
    networks."12-wireless" = {
      matchConfig.Name = ["wlp3s0"];
      DHCP = "yes";
    };
    networks."12-wired" = {
      matchConfig.Name = ["enp0s25"];
      linkConfig.RequiredForOnline = false;
      DHCP = "yes";
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  services.xserver.enable = true;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  programs.command-not-found.enable = true;

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

  users.users.julius.packages = with pkgs; [
    element-desktop-wayland
    (pkgs.himalaya.override {buildFeatures = ["notmuch"];})
    notmuch
    nextcloud-client
    wl-clipboard
    thunderbird # keine zeit für sparifankerl
  ];

  networking.extraHosts = ''
    0.0.0.0 pr0gramm.com
  '';

  system.stateVersion = "24.05";
}
