# "${modulesPath}/virtualisation/digital-ocean-image.nix" exists, but I don't like the resulting image
# .#nixosConfigurations.doggieworld.config.system.build.digitalOceanImage
{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = ["${modulesPath}/virtualisation/digital-ocean-config.nix"];
  config.virtualisation.digitalOcean = {
    setRootPassword = false;
    setSshKeys = false;
    seedEntropy = true;
    rebuildFromUserData = false;
  };

  config.system.build.digitalOceanImage = import "${modulesPath}/../lib/make-disk-image.nix" {
    inherit config lib pkgs;
    name = "digital-ocean-image";
    format = "qcow2";
    postVM = ''
      #zstd $diskImage
    '';
    configFile = null;
    diskSize = "auto";
    partitionTableType = "efi";
    # can't do this
    # pkgs = pkgs // { e2fsprogs = pkgs.bcachefs-tools; }; # hack around
    # fsType = "bcachefs";
  };
}
