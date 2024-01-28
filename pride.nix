{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    ./common.nix
    ./graphical.nix
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 15;
      editor = false;
    };
    efi.canTouchEfiVariables = true;
  };
  boot.supportedFilesystems = ["bcachefs"];
  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];

  # parted /dev/nvme1n1 -- mklabel gpt
  # parted /dev/nvme1n1 -- mkpart ESP fat32 1MB 512MB
  # parted /dev/nvme1n1 -- set 1 esp on
  # parted /dev/nvme1n1 -- mkpart primary 512MB 100%
  # mkfs.fat -F 32 -n nixboot /dev/nvme1n1p1
  # nix-env -iA nixos.keyutils
  # keyctl link @u @s # bug
  # bcachefs format --encrypted --label nixroot /dev/nvme1n1p2 # Labels don't work. :(
  # bcachefs unlock /dev/nvme1n1p2
  # mount /dev/nvme1n1p2 /mnt
  # mkdir /mnt/boot
  # mount /dev/nvme1n1p1 /mnt/boot
  fileSystems = {
    "/" = {
      device = "/dev/nvme1n1p2";
      fsType = "bcachefs";
      options = ["compression=zstd"];
    };
    "/boot" = {
      device = "/dev/disk/by-label/nixboot";
      fsType = "vfat";
    };
  };

  swapDevices = [];

  networking.useDHCP = false;
  networking.useNetworkd = true; # TODO translate
  networking.interfaces.enp5s0.ipv4.addresses = [
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

  services.xserver.enable = true;
  services.xserver.videoDrivers = ["nvidia"];
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  nixpkgs.config.allowUnfreePredicate = let
    hasPrefix = pfx: str: lib.strings.removePrefix pfx str != pfx;
  in
    pkg: hasPrefix "nvidia-" (lib.getName pkg);

  services.xserver = {
    displayManager.gdm = {
      enable = true;
      autoSuspend = false;
    };
    desktopManager.gnome = {
      enable = true;
      extraPackages = with pkgs;
      with gnomeExtensions; [
        desktop-cube
        burn-my-windows
      ];
    };
  };

  users = let
    keys = [
      "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAAqmN0bQWftRFvSCFRmIct6nvwoosuX3hqfp+4uKhUdDxDOThqqqturJUEpovz6Jb/p9nQPee+hMkCMDmpNIEPTKgDaD+MY58tX3bcayHBAoGPyY+RMOaEvHQ+AWjicVqE7Yo9E27sbELIbp0p9QSGDYTaN690ap7KjpoyhlpAvOkV++Q== julius"
    ];
  in {
    users.root.openssh.authorizedKeys.keys = keys;
    users.julius.openssh.authorizedKeys.keys = keys;
  };
  services.openssh.enable = true;

  system.stateVersion = "23.11";
}
