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
    ({lib, ...}: {
      imports = ["${modulesPath}/installer/${mod}"];
      config.users.users.yamaguchi = lib.mkForce {isNormalUser = true;};
    });
  vm = {
    lib,
    modulesPath,
    ...
  }: {
    imports = [
      "${modulesPath}/virtualisation/qemu-vm.nix"
    ];
    boot.initrd.secrets = lib.mkForce {};
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
    networking.supplicant = lib.mkForce {};
    networking.wireless = lib.mkForce {};
    networking.wireguard.interfaces = lib.mkForce {};
  };
in {
  # nix build --show-trace -vL .#nixosConfigurations.${host}.config.system.build.installer.isoImage
  config.system.build.installer = vari "cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix";
  config.system.build.installerGui = vari "cd-dvd/installation-cd-graphical-gnome.nix";
  # nix build --show-trace -vL .#nixosConfigurations.${host}.config.system.build.netboot.kexecTree
  config.system.build.netboot = vari "netboot/netboot-minimal.nix";
  # env $"SHARED_DIR=(pwd)/share" nix run -vL .#nixosConfigurations.(hostname).config.system.build.test.vm
  config.system.build.test = var vm;
  config.system.build.testGui = var ({lib, ...}: {
    imports = [vm ./graphical.nix];
    virtualisation.graphics = lib.mkForce true;
    services.xserver = {
      displayManager = {
        autoLogin.user = "julius";
        defaultSession = "none+twm"; # TODO: Find a way to pass super from the host, then we use the host's WM
      };
      windowManager.twm.enable = true;
    };
  });
}
