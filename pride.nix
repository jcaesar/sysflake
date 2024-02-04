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
  systemd.network = {
    enable = true;
    networks."10-cameo-net" = {
      matchConfig.Name = "eth0";
      DHCP = "no";
      address = ["10.13.52.20/25"];
      dns = ["10.13.52.1" "9.9.9.9"];
      gateway = [
        "10.13.52.1"
      ];
    };
    netdevs."11-wg-dev" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
        #MTUBytes = "1350";
      };
      wireguardConfig = {
        PrivateKeyFile = "/etc/secrets/wg.pk";
        ListenPort = 16816;
      };
      wireguardPeers = [
        {
          wireguardPeerConfig = {
            PublicKey = "3dY3B1IlbCuBb8FrZ472u+cGXihRGE6+qmo5RZlHdFg=";
            Endpoint = "128.199.185.74:13518";
            AllowedIPs = ["10.13.38.0/24" "fc00:1337:dead:beef:caff::0/96"];
            PersistentKeepalive = 29;
          };
        }
      ];
    };
    networks."11-wg-net" = {
      matchConfig.Name = "wg0";
      address = ["10.13.38.8/24" "fc00:1337:dead:beef:caff::8/96"];
      DHCP = "no";
      networkConfig = {
        IPv6AcceptRA = false;
      };
    };
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
  nixpkgs.config.cudaSupport = true;
  nixpkgs.config.allowUnfreePredicate = pkg:
    (
      name:
        (builtins.match "^(nvidia-|cuda_).*" name != null)
        || (builtins.elem name [
          "cudnn"
          "libcublas"
          "libcufft"
          "libcurand"
          "libcusolver"
          "libcusparse"
          "libnvjitlink"
          "libnpp"
        ])
    ) (lib.getName pkg);

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
  services.prometheus.exporters.node.enable = true;

  system.stateVersion = "23.11";
}
