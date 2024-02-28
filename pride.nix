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
    ./dlna.nix
    ./prometheus-nvml-exporter.nix
    (import ./ssh-unlock.nix {
      authorizedKeys = import ./julius-home-ssh.nix;
      extraModules = ["igb"];
    })
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
    "/mnt/file" = {
      device = "/dev/disk/by-uuid/1521d981-c56e-4c80-af64-ac1ad11ef80b";
      fsType = "btrfs";
    };
    "/mnt/cameo" = {
      device = "/dev/disk/by-uuid/e890f00d-912d-414f-ac26-918a2bc840d1";
      fsType = "btrfs";
    };
  };

  boot.initrd.luks.devices = let
    dev = uuid: {
      device = "/dev/disk/by-uuid/${uuid}";
      keyFile = "/etc/secrets/filkey";
    };
  in {
    "file1" = dev "c2b6f644-c505-4d8e-be79-db0d80dd149d";
    "file2" = dev "ba5c6f26-ebfc-475b-9801-713b66ed55fb";
    "cameo1" = dev "4d8fe471-1685-4540-844c-d76000911869";
    "cameo2" = dev "54b76e1d-ce44-4dad-93c4-a8f3030da827";
  };

  swapDevices = [];

  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks."10-cameo-net" = {
      matchConfig.Name = "enp5s0";
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
          "unrar"
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
  users.users.julius.extraGroups = ["nzbget"];
  users.users.julius.packages = with pkgs; [
    browsh
  ];

  users.users.root.openssh.authorizedKeys.keys = import ./julius-home-ssh.nix;
  users.users.julius.openssh.authorizedKeys.keys = import ./julius-home-ssh.nix;

  services.openssh.enable = true;
  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true;
  };

  services.nzbget = {
    enable = true;
    settings.MainDir = "/mnt/file/nzbget";
  };
  networking.firewall.allowedTCPPorts = [6789];
  services.minidlna = {
    enable = true;
    openFirewall = true;
    settings = {
      inotify = "yes";
      media_dir = [
        "V,/mnt/file/nzbget/dst/"
        "V,/mnt/cameo/@/home/julius/media/"
      ];
    };
  };
  systemd.services.minidlna.serviceConfig.SupplementaryGroups = "nzbget";

  system.stateVersion = "23.11";
}
