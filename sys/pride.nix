{
  lib,
  pkgs,
  ...
}: let
  private = import ../private.nix;
in {
  njx.common = true;
  njx.graphical = true;
  njx.binfmt = true;
  njx.dlna = true;
  njx.prometheus-nvml-exporter = true;
  njx.docker = true;

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
  njx.sshUnlock.keys = private.terminalKeys;
  njx.sshUnlock.modules = ["igb"];

  disko.devices.disk.diks = {
    device = "/dev/disk/by-id/nvme-ADATA_SX8200PNP_2J3020071323_1";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          type = "EF00";
          size = "500M";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        root = {
          size = "100%";
          content = {
            type = "luks";
            name = "nixcrypt";
            settings.allowDiscards = true;
            content = {
              type = "filesystem";
              format = "btrfs";
              mountpoint = "/";
              mountOptions = ["defaults" "discard=async" "relatime" "compress=zstd"];
            };
          };
        };
      };
    };
  };

  fileSystems = {
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
      keyFile = "/sysroot/etc/secrets/filekey";
    };
  in {
    "file1" = dev "c2b6f644-c505-4d8e-be79-db0d80dd149d";
    "file2" = dev "ba5c6f26-ebfc-475b-9801-713b66ed55fb";
    "cameo1" = dev "4d8fe471-1685-4540-844c-d76000911869";
    "cameo2" = dev "54b76e1d-ce44-4dad-93c4-a8f3030da827";
  };
  njx.manual.hdd-key = ''
    Not entering 5 encryption passwords at boot requires a keyfile added to the 4 HDDs at
    /etc/secrets/filekey
  '';

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
  njx.wireguardToDoggieworld = {
    enable = true;
    listenPort = 16816;
    finalOctet = 8;
  };

  hardware.cpu.amd.updateMicrocode = true;

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
  environment.systemPackages = with pkgs; [
    gnomeExtensions.desktop-cube
    gnomeExtensions.burn-my-windows
    hdparm
  ];
  users.users.julius.extraGroups = ["nzbget"];
  users.users.julius.packages = with pkgs; [
    pyanidb
    browsh
    meshlab
    # python3Packages.opensfm # todo
    opensplat
    colmap
    archivebox
    pyanidb
    ffmpeg
    piper-tts
  ];

  users.users.root.openssh.authorizedKeys.keys = private.terminalKeys;
  users.users.julius.openssh.authorizedKeys.keys = builtins.concatLists [(import ../work.nix).sshKeys.strong private.terminalKeys];

  services.openssh.enable = true;
  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true;
    njx.powercap = true;
  };

  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  services.nzbget = {
    enable = true;
    settings.MainDir = "/mnt/file/nzbget";
  };

  networking.firewall.allowedTCPPorts = [6789 9151];

  system.stateVersion = "23.11";
}
