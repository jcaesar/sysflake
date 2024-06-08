{
  extendModules,
  modulesPath,
  ...
}: let
  ext = modules:
    (extendModules {
      inherit modules;
    })
    .config
    .system
    .build;
  base = {lib, ...}: {
    boot.initrd.luks.devices = lib.mkForce {};
    fileSystems = {};
    boot.supportedFilesystems.zfs = lib.mkForce false;
  };
  common = {lib, ...}: {
    imports = [base];
    users.users.yamaguchi = lib.mkForce {isNormalUser = true;};
    boot.initrd.systemd.enable = lib.mkForce false;
  };
  iso = _: {
    imports = [common];
    isoImage.squashfsCompression = "zstd -Xcompression-level 6";
  };
  sd = {
    lib,
    config,
    ...
  }: {
    imports = [common];
    fileSystems = lib.mkForce {
      "/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
      };
      "/boot" = {
        device = "/dev/disk/by-label/FIRMWARE";
        fsType = "vfat";
      };
    };
    sdImage = let
      h = builtins.hashString "sha256" config.networking.hostName;
      h12 = builtins.substring 0 12 h;
    in {
      rootPartitionUUID = "00000000-0000-0000-0001-${h12}";
      compressImage = false;
    };
  };
  vm = {
    lib,
    modulesPath,
    ...
  }: {
    imports = [
      base
      "${modulesPath}/virtualisation/qemu-vm.nix"
    ];
    boot.initrd.secrets = lib.mkForce {};
    services.getty.autologinUser = "root";
    virtualisation.graphics = false;
    virtualisation.memorySize = 2048;
    systemd.services.digitalocean-metadata.enable = false;
    systemd.services.growpart.enable = false;
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
    services.knot.keyFiles = [];
  };
  guivm = {lib, ...}: {
    imports = [vm ./graphical.nix];
    virtualisation.graphics = lib.mkForce true;
    services.xserver = {
      windowManager.twm.enable = true;
    };
    services.displayManager = {
      autoLogin.user = "julius";
      defaultSession = lib.mkForce "none+twm"; # TODO: Find a way to pass super from the host, then we use the host's WM
    };
  };
in {
  # nix build --show-trace -vL .#nixosConfigurations.${host}.config.system.build.installer.isoImage
  system.build.installer = ext [iso "${modulesPath}/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"];
  system.build.installerOldKernel = ext [iso "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"];
  system.build.installerGui = ext [iso "${modulesPath}/installer/cd-dvd/installation-cd-graphical-gnome.nix"];
  # nix build --show-trace -vL .#nixosConfigurations.${host}.system.build.netboot.kexecTree
  system.build.netboot = ext [common "${modulesPath}/installer/netboot/netboot-minimal.nix"];
  system.build.aarchSd = ext [sd "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"];
  system.build.aarchSdInstaller = ext [sd "${modulesPath}/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"];
  # env $"SHARED_DIR=(pwd)/share" nix run -vL .#nixosConfigurations.(hostname).system.build.test.vm
  system.build.test = ext [vm];
  system.build.testGui = ext [guivm];
}
