{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    ./common.nix
    ./graphical.nix
    (modulesPath + "/installer/scan/not-detected.nix")
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

  networking.useDHCP = lib.mkDefault true;
  #networking.wireless.enable = true;
  networking.supplicant.wlp3s0.configFile.writable = true;
  networking.supplicant.wlp3s0.configFile.path = "/etc/wpa_supplicant.conf";
  networking.wireless.userControlled.enable = true;
  networking.wireguard.interfaces = {
    wg0 = {
      ips = ["10.13.38.2/24" "fc00:1337:dead:beef:caff::2/96"];
      listenPort = 51820;
      privateKeyFile = "/mnt/oldroot/etc/wireguard/wg-private.key";
      peers = [
        {
          publicKey = "3dY3B1IlbCuBb8FrZ472u+cGXihRGE6+qmo5RZlHdFg=";
          allowedIPs = ["10.13.38.0/24" "10.13.44.0/24" "fc00:1337:dead:beef:caff::/96"];
          endpoint = "128.199.185.74:13518";
          persistentKeepalive = 29;
        }
      ];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 15;
      editor = false;
    };
    efi.canTouchEfiVariables = true;
  };
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "prohibit-password";
    settings.ListenAddress = "0.0.0.0:2222";
  };
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

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
    (himalaya.override {buildFeatures = ["notmuch"];})
    notmuch
    nextcloud-client
  ];

  system.stateVersion = "24.05";
}
