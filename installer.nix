# https://nixos.wiki/wiki/Bcachefs#Generate_bcachefs_enabled_installation_media
# nix build .#nixosConfigurations.installerBCacheFS.config.system.build.isoImage
{
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix"
    ./base.nix
  ];
  boot.supportedFilesystems = ["bcachefs"];
  boot.kernelPackages = lib.mkOverride 0 pkgs.linuxPackages_latest;
}
