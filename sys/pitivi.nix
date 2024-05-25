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
      extraModules = ["brcmfmac"];
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
  users.users.root.openssh.authorizedKeys.keys = private.terminalKeys;

  disko.devices.disk.diks = {
    device = "/dev/mmcblk0";
    type = "disk";
    content = {
      type = "table";
      format = "msdos";
      partitions = [
        {
          name = "BOOT";
          start = "8M";
          end = "500M";
          bootable = true;
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        }
        {
          name = "luks";
          start = "500M";
          end = "100%";
          content = {
            type = "luks";
            name = "crypted";
            settings.allowDiscards = true;
            #passwordFile = "/tmp/secret.key";
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

  system.stateVersion = "24.05";
}
