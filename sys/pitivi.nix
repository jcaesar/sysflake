{lib, ...}: let
  private = import ../private.nix;
in {
  imports = [
    ../mod/base.nix
    ../mod/dlna.nix
    (import ../mod/ssh-unlock.nix {
      authorizedKeys = private.terminalKeys;
      extraModules = ["smsc95xx" "e1000e"];
    })
  ];

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.initrd.secrets = lib.mkForce {};

  networking.hostName = "pitivi";

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
  };
  system.stateVersion = "24.05";
}
