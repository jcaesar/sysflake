{
  pkgs,
  lib,
  ...
}: let
  common = import ../work.nix;
  intake = "/dev/sdb";
  exhaust = "/dev/sdc";
in {
  imports = [
    ../mod/base.nix
    common.config
    (import ../mod/ssh-unlock.nix {
      authorizedKeys = common.sshKeys.strong;
      extraModules = ["igb" "i40e"];
    })
    ../mod/squid.nix
    ../mod/binfmt.nix
  ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "nvme" "megaraid_sas" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = ["dm-snapshot"];
  boot.kernelModules = ["kvm-intel"];
  hardware.cpu.intel.updateMicrocode = true;

  disko.devices.disk = {
    exhaust = {
      device = exhaust;
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
              content = {
                type = "filesystem";
                format = "btrfs";
                mountpoint = "/";
                mountOptions = ["defaults" "relatime" "compress=zstd"];
              };
            };
          };
        };
      };
    };
    intake = {
      device = intake;
      type = "disk";
      content = {
        type = "luks";
        name = "filecrypt";
        content = {
          type = "btrfs";
          subvolumes = {
            "var" = {
              mountpoint = "/var";
            };
            "home" = {
              mountOptions = ["compress=zstd"];
              mountpoint = "/home";
            };
          };
        };
      };
    };
  };
  # requires some manual work
  # dd if=/dev/random out=/etc/secrets/filekey bs=4k
  # chmod 400 /etc/secrets/filekey
  # cryptsetup luksAddKey /dev/sdb /etc/secrets/filekey
  boot.initrd.luks.devices.intake = {
    device = intake;
    keyFile = "/sysroot/etc/secrets/filekey";
  };

  users.users.root.openssh.authorizedKeys.keys =
    common.sshKeys.strong
    ++ common.sshKeys.aoki;
  networking.proxy.default = "http://10.13.24.255:3128/";
  systemd.network = {
    enable = true;
    networks."10-fnet" = {
      matchConfig.Name = "eno1";
      DHCP = "no";
      address = ["10.38.90.51/24"];
      gateway = ["10.38.90.1"];
      inherit (common) dns ntp;
    };
  };
  networking.hostName = "gemini5";

  environment.systemPackages = (with pkgs; [logcheck]) ++ common.packages pkgs;

  system.stateVersion = "23.05";
}
