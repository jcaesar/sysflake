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

  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "sd_mod" "sdhci_pci"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  fileSystems."/" = {
    device = "UUID=9972f2d9-9d2a-48e1-b29e-097ac1e73557";
    fsType = "bcachefs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/FFCF-1070";
    fsType = "vfat";
  };

  networking.useDHCP = lib.mkDefault true;
  networking.supplicant.wlp3s0.configFile.writable = true;
  networking.supplicant.wlp3s0.configFile.path = "/etc/wpa_supplicant.conf";
  networking.wireless.userControlled.enable = true;

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
  };

  users.users.julius.packages = with pkgs; [
    element-desktop-wayland
    (himalaya.override {buildFeatures = ["notmuch"];})
    notmuch
  ];

  system.stateVersion = "24.05";
}
