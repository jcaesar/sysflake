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
    "${modulesPath}/installer/scan/not-detected.nix"
    ../mod/common.nix
    ../mod/graphical.nix
    ../mod/binfmt.nix
    ../mod/dlna.nix
    ../mod/prometheus-nvml-exporter.nix
    (import ../mod/ssh-unlock.nix {
      authorizedKeys = private.terminalKeys;
      extraModules = ["igb"];
    })
    (private.wireguardToDoggieworld {
      listenPort = 16816;
      finalOctet = 8;
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
    #"/mnt/file" = {
    #  device = "/dev/disk/by-uuid/1521d981-c56e-4c80-af64-ac1ad11ef80b";
    #  fsType = "btrfs";
    #};
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
    #"file1" = dev "c2b6f644-c505-4d8e-be79-db0d80dd149d";
    #"file2" = dev "ba5c6f26-ebfc-475b-9801-713b66ed55fb";
    "cameo1" = dev "4d8fe471-1685-4540-844c-d76000911869";
    "cameo2" = dev "54b76e1d-ce44-4dad-93c4-a8f3030da827";
  };

  swapDevices = [];

  systemd.network = {
    enable = true;
    networks."10-cameo-net" = {
      matchConfig.Name = "enp5s0";
      DHCP = "no";
      address = ["10.13.52.20/25"];
      dns = ["10.13.52.1" "9.9.9.9"];
      gateway = ["10.13.52.1"];
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
  nixpkgs.config = {
    cudaSupport = true;
    cudaCapabilities = ["7.5"];
    cudaForwardCompat = false;
    allowUnfreePredicate = pkg:
      (
        name:
          (builtins.match "^(nvidia-|cuda_|cuda-).*" name != null)
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
  };

  services.xserver = {
    displayManager.gdm.enable = true;
    desktopManager.gnome = {
      enable = true;
    };
  };
  environment.systemPackages = with pkgs;
  with gnomeExtensions; [
    desktop-cube
    burn-my-windows
    meshlab
    python3Packages.opensfm
    opensplat
    ((colmap.override {
        freeimage = freeimage.overrideAttrs {
          meta = freeimage.meta // {knownVulnerabilities = [];};
        };
        mkDerivation = cudaPackages.backendStdenv.mkDerivation;
      })
      .overrideAttrs (prev: {
        cmakeFlags = ["-DUSE_CUDA=ON" "-DCMAKE_CUDA_ARCHITECTURES=75"];
        nativeBuildInputs = prev.nativeBuildInputs ++ [pkgs.qt5.wrapQtAppsHook];
        buildInputs = prev.buildInputs ++ [
          flann
          cgal
          gmp
          mpfr
          xorg.libSM
        ];
        src = fetchFromGitHub {
          owner = "colmap";
          repo = "colmap";
          rev = "3.9.1";
          hash = "sha256-Xb4JOttCMERwPYs5DyGKHw+f9Wik1/rdJQKbgVuygH8=";
        };
      }))
  ];
  users.users.julius.extraGroups = ["nzbget"];
  users.users.julius.packages = with pkgs; [
    pyanidb
    browsh
  ];

  users.users.root.openssh.authorizedKeys.keys = private.terminalKeys;
  users.users.julius.openssh.authorizedKeys.keys = builtins.concatLists [(import ../work.nix).sshKeys.strong private.terminalKeys];

  services.openssh.enable = true;
  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true;
  };
  systemd.services.prometheus-node-exporter.serviceConfig = {
    SupplementaryGroups = "powercap";
    ExecStartPre = ["+${pkgs.findutils}/bin/find /sys/devices/virtual/powercap -name energy_uj -exec chmod g+r -R {} + -exec chown root:powercap {} +"];
  };
  users.groups.powercap = {};

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  #services.nzbget = {
  #  enable = true;
  #  settings.MainDir = "/mnt/file/nzbget";
  #};
  services.minidlna = {
    enable = true;
    openFirewall = true;
    settings = {
      inotify = "yes";
      media_dir = [
        #"V,/mnt/file/nzbget/dst/"
        "V,/mnt/cameo/@/home/julius/media/"
      ];
    };
  };
  #systemd.services.minidlna.serviceConfig.SupplementaryGroups = "nzbget";

  networking.firewall.allowedTCPPorts = [6789 9151];

  system.stateVersion = "23.11";
}
