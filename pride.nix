{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: rec {
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    ./common.nix
    ./graphical.nix
    ./prometheus-nvml-exporter.nix
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
  cudaSupport = true;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.match "^(nvidia-|cuda_).*" (lib.getName pkg) != null;

  services.xserver = {
    displayManager.gdm = {
      enable = true;
      autoSuspend = false;
    };
    desktopManager.gnome = {
      enable = true;
    };
  };
  environment.systemPackages = with pkgs;
  with gnomeExtensions; [
    desktop-cube
    burn-my-windows
    ollama
  ];
  users.users.julius.packages = with pkgs; [
    browsh
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAAqmN0bQWftRFvSCFRmIct6nvwoosuX3hqfp+4uKhUdDxDOThqqqturJUEpovz6Jb/p9nQPee+hMkCMDmpNIEPTKgDaD+MY58tX3bcayHBAoGPyY+RMOaEvHQ+AWjicVqE7Yo9E27sbELIbp0p9QSGDYTaN690ap7KjpoyhlpAvOkV++Q== julius"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEl5k7aYexi95LNugqwBZQAk/qmA3bruEYqQqFgSpnXSLDeNX0ZZNa8NekuN+Cf7qm9ZJsWZpKzEOi7C//hZa2E= julius@korsika"
  ];
  users.users.julius.openssh.authorizedKeys.keys = users.users.root.openssh.authorizedKeys.keys;
  services.openssh.enable = true;

  system.stateVersion = "23.11";
}
