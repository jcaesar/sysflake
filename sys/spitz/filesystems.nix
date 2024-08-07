{
  boot.supportedFilesystems = ["bcachefs"];
  disko.devices.disk.diks = {
    device = "/dev/nvme0n1";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          type = "EF00";
          size = "1G";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        root = {
          size = "300G";
          content = {
            type = "luks";
            name = "nixcrypt";
            settings.allowDiscards = true;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = ["defaults" "relatime"];
            };
          };
        };
        store = {
          size = "100G";
          content = {
            type = "filesystem";
            format = "bcachefs";
            mountpoint = "/nix/store";
          };
        };
      };
    };
  };
}
