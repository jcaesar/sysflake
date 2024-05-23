{
  boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "usbhid" "sr_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/5c48d0e8-10ac-4838-8e4c-436b43508ab5";
    fsType = "btrfs";
  };

  boot.initrd.luks.devices."crypt".device = "/dev/disk/by-uuid/9edf443f-250f-4550-98ef-d075d37a833b";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0A89-4756";
    fsType = "vfat";
  };

  swapDevices = [];

  hardware.cpu.intel.updateMicrocode = true;
}
