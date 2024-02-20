{
  config,
  extendModules,
  lib,
  modulesPath,
  ...
}: let
  var = mod:
    (extendModules {
      modules = [
        ({config, ...}: {
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
  config.system.build.installer = vari "cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix";
  #   sys = main: sysSingle ({...}: {}) main //
  # {
  #   installerMinimal = sysSingle "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix" main;
  #   installerGraphical = sysSingle "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix" main;
  #   # nix build --show-trace -vL .#nixosConfigurations.${host}.netbootMinimal.config.system.build.kexecTree
  #   netbootMinimal = sysSingle "${nixpkgs}/nixos/modules/installer/netboot/netboot-minimal.nix" main;
  # };
  # }
}
