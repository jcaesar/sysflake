{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    # FS setup according to https://nixos.wiki/wiki/ZFS#Simple_NixOS_ZFS_installation
    "${modulesPath}/installer/scan/not-detected.nix"
  ];

  #boot.loader.systemd-boot.enable = true;
  #boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.grub = {
    enable = true;
    zfsSupport = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = [
      {
        devices = ["nodev"];
        path = "/boot";
      }
    ];
  };

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];

  fileSystems = let
    zfs = sub: {
      device = "nixpool/${sub}";
      fsType = "zfs";
    };
  in {
    "/" = zfs "root";
    "/nix" = zfs "nix";
    "/var" = zfs "var";
    "/home" = zfs "home";
    "/boot" = {
      device = "/dev/disk/by-label/nixboot";
      fsType = "vfat";
    };
  };

  swapDevices = [];

  networking.useDHCP = false;
  networking.useNetworkd = true; # TODO translate
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.13.52.20";
      prefixLength = 24;
    }
  ];

  networking.defaultGateway = {
    address = "10.13.52.1";
    interface = "eth0";
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  networking.hostName = "pride";
  networking.hostId = "7ef47bc5";

  time.timeZone = "Asia/Tokyo";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  services.xserver.enable = true;
  services.xserver.videoDrivers = ["nvidia"];
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    enableNvidiaPatches = true;
  };
  nixpkgs.config.allowUnfreePredicate = let
    hasPrefix = pfx: str: lib.strings.removePrefix pfx str != pfx;
  in
    pkg: hasPrefix "nvidia-" (lib.getName pkg);

  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.xserver.xkb = {
    layout = "us";
    options = "compose:caps";
    variant = "altgr-intl";
  };

  hardware.pulseaudio.enable = false;
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
    extraGroups = ["wheel"]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      firefox
      tree
    ];
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAAqmN0bQWftRFvSCFRmIct6nvwoosuX3hqfp+4uKhUdDxDOThqqqturJUEpovz6Jb/p9nQPee+hMkCMDmpNIEPTKgDaD+MY58tX3bcayHBAoGPyY+RMOaEvHQ+AWjicVqE7Yo9E27sbELIbp0p9QSGDYTaN690ap7KjpoyhlpAvOkV++Q== julius"
  ];

  environment.systemPackages = with pkgs; [
    vim
    wget
    helix
    git
    efibootmgr
  ];

  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # system.copySystemConfiguration = true;

  system.stateVersion = "23.11"; # Do not change https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
}