{
  pkgs,
  lib,
  ...
}: let
  common = import ../work.nix;
in {
  njx.base = true;
  njx.squid = true;
  njx.binfmt = true;
  njx.work = true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "nvme" "megaraid_sas" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = ["dm-snapshot"];
  boot.kernelModules = ["kvm-intel"];
  hardware.cpu.intel.updateMicrocode = true;

  njx.sshUnlock.keys = common.sshKeys.strong;
  njx.sshUnlock.modules = ["igb" "i40e"];
  disko.devices.disk = {
    exhaust = {
      device = "/dev/disk/by-id/nvme-INTEL_SSDPED1K750GAC_PHKS8163009T750BGN";
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
  };
  # # requires some manual work
  # # dd if=/dev/random out=/etc/secrets/filekey bs=4k
  # # chmod 400 /etc/secrets/filekey
  # # cryptsetup luksAddKey /dev/sdb /etc/secrets/filekey
  # boot.initrd.luks.devices.intake = {
  #   device = intake;
  #   keyFile = "/sysroot/etc/secrets/filekey";
  # };

  users.users.root.openssh.authorizedKeys.keys =
    common.sshKeys.strong
    ++ common.sshKeys.aoki;
  networking.proxy.default = "http://10.13.24.255:3128/";
  systemd.network = {
    enable = true;
    netdevs."8-stubbytoe".netdevConfig = {
      Name = "stubbytoe";
      Kind = "dummy";
      MACAddress = "de:ad:be:ef:ca:fe";
    };
    networks."9-stubbytoe" = {
      matchConfig.Name = "stubbytoe";
      address = ["10.13.24.255/32"];
    };
    networks."10-fnet" = {
      matchConfig.Name = "eno1";
      DHCP = "no";
      address = ["10.38.90.51/24"];
      gateway = ["10.38.90.1"];
      inherit (common) dns ntp;
    };
  };
  networking.hostName = "gemini5";

  environment.systemPackages = with pkgs; [logcheck];

  system.stateVersion = "23.05";
}
