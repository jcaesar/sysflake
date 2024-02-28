{
  authorizedKeys,
  bootDisks ? ["/" "/boot"],
  extraModules ? [],
}: {config, ...}: {
  # remote luks unlock: ssh -tt $host systemd-cryptsetup attach $luks $disk
  boot.initrd.kernelModules = extraModules;
  boot.initrd = {
    systemd = {
      enable = true;
      network = {
        enable = true;
        networks = config.systemd.network.networks;
      };
    };
    network = {
      enable = true;
      ssh = {
        enable = true;
        port = 2223;
        hostKeys = [
          # mkdir -p /etc/ssh/boot && chmod 700 /etc/ssh/boot && for a in rsa ed25519; do ssh-keygen -t $a -N "" -f /etc/ssh/boot/host_$a_key; done
          "/etc/ssh/boot/host_rsa_key"
          "/etc/ssh/boot/host_ed25519_key"
        ];
        authorizedKeys = authorizedKeys;
      };
    };
  };
  fileSystems =
    builtins.listToAttrs
    (map
      (name: {
        inherit name;
        value = {options = ["x-systemd.device-timeout=infinity"];};
      })
      bootDisks);
}
