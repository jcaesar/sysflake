{
  pkgs,
  lib,
  ...
}: let
  private = import ../private.nix;
in {
  imports = [
    ../mod/base.nix
    ../mod/dlna.nix
    (import ../mod/ssh-unlock.nix {
      authorizedKeys = private.terminalKeys;
      extraModules = ["brcmfmac" "smsc95xx"];
    })
  ];

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.initrd.secrets = lib.mkForce {};
  hardware.enableRedistributableFirmware = true; # apparently, this also requires:
  nixpkgs.overlays = [
    (self: super: {
      firmwareLinuxNonfree = super.firmwareLinuxNonfree.overrideAttrs (old: {
        version = "2020-12-18";
        src = pkgs.fetchgit {
          url = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
          rev = "b79d2396bc630bfd9b4058459d3e82d7c3428599";
          sha256 = "1rb5b3fzxk5bi6kfqp76q1qszivi0v1kdz1cwj2llp5sd9ns03b5";
        };
        outputHash = "1p7vn2hfwca6w69jhw5zq70w44ji8mdnibm1z959aalax6ndy146";
      });
    })
  ];

  # https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_3#Early_boot
  boot.initrd.kernelModules = ["vc4" "bcm2835_dma" "i2c_bcm2835"];
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.consoleLogLevel = lib.mkDefault 7;

  networking.hostName = "pitivi";
  networking.supplicant.wlan0.configFile.path = "/etc/wpa_supplicant.conf";
  networking.supplicant.wlan0.userControlled.enable = true;
  networking.supplicant.wlan0.configFile.writable = true;
  networking.supplicant.wlan0.extraConf = "country=JP";
  systemd.network = {
    enable = true;
    networks."12-wireless" = {
      matchConfig.Name = ["wlan0"];
      DHCP = "yes";
    };
    networks."12-wired" = {
      matchConfig.Name = ["enu1u1"];
      linkConfig.RequiredForOnline = false;
      DHCP = "yes";
    };
  };
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = private.terminalKeys ++ [private.prideKey];

  disko.devices.disk.diks = {
    device = "/dev/mmcblk0";
    type = "disk";
    content = {
      type = "table";
      format = "msdos";
      partitions = [
        {
          name = "FIRMWARE";
          start = "8M";
          end = "50M";
          fs-type = "fat32";
          content = {
            type = "filesystem";
            format = "vfat";
            # still need to manually copy firmware here
            mountpoint = "/boot/firmware";
          };
        }
        {
          name = "BOOT";
          start = "50M";
          end = "1G";
          bootable = true;
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/boot";
          };
        }
        {
          name = "store";
          start = "1G";
          end = "60%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix/store";
          };
        }
        {
          name = "luks";
          start = "60%";
          end = "100%";
          content = {
            type = "luks";
            name = "crypted";
            settings.allowDiscards = true;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        }
      ];
    };
  };

  services.home-assistant = {
    enable = true;
    extraComponents = [
      "met"
      "radio_browser"
      "media_player"
      "zha"
      "bluetooth_tracker"
      "bluetooth_le_tracker"
      "bluetooth"
      "bluetooth_adapters"
      "generic_thermostat"
      "dhcp"
    ];
    config = {
      default_config = {};
    };
  };

  system.stateVersion = "24.05";
}
