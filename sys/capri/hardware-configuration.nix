{
  imports = [];

  boot.initrd.availableKernelModules = ["ata_piix" "mptspi" "sd_mod" "sr_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/0d48d125-29e5-4dc1-8e2c-3e2dfb5d8f66";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [];
}
