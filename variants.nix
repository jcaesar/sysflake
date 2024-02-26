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
  # env $"SHARED_DIR=(pwd)/share" nix run -vL .#nixosConfigurations.(hostname).config.system.build.test.vm
  config.system.build.test = var ({
    lib,
    modulesPath,
    ...
  }: {
    imports = [
      "${modulesPath}/virtualisation/qemu-vm.nix"
    ];
    services.getty.autologinUser = "root";
    virtualisation.graphics = false;
    virtualisation.memorySize = 2048;
    systemd.network = lib.mkForce {
      enable = true;
      networks."10-test-vm-net" = {
        matchConfig.Name = "eth0";
        DHCP = "yes";
      };
    };
    # implicit: autologin for root, writable store
  });
}
