{
  extendModules,
  modulesPath,
  ...
}: let
  var = mod:
    (extendModules {
      modules = [
        ({lib, ...}: {
          config.boot.initrd.luks.devices = lib.mkForce {};
          config.fileSystems = {};
        })
        mod
      ];
    })
    .config
    .system
    .build;
  vari = mod:
    var
    "${modulesPath}/installer/${mod}";
in {
  # nix build --show-trace -vL .#nixosConfigurations.${host}.config.system.build.installer.isoImage
  config.system.build.installer = vari "cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix";
  config.system.build.installerGui = vari "cd-dvd/installation-cd-graphical-gnome.nix";
  # nix build --show-trace -vL .#nixosConfigurations.${host}.config.system.build.netboot.kexecTree
  config.system.build.netboot = vari "netboot/netboot-minimal.nix";
}
