# remote luks unlock: $ ssh $host -p2223 -tt systemctl restart systemd-ask-password-console
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types;
  listOfStrings = types.listOf types.string;
  eso = mkOption {
    type = listOfStrings;
    default = [];
  };
  key = "sshUnlock";
  cfg = config.njx.${key};
in {
  options.njx.${key} = {
    keys = eso;
    modules = eso;
    bootDisks = mkOption {
      type = listOfStrings;
      default = ["/" "/boot"];
      description = "Don't fail boot even if these disks don't get unlocked quickly";
    };
  };

  config = lib.mkIf (cfg.keys != []) {
    boot.initrd.kernelModules = cfg.modules;
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
            # mkdir -p /etc/ssh/boot && chmod 700 /etc/ssh/boot && for a in rsa ed25519; do ssh-keygen -t $a -N "" -f /etc/ssh/boot/host_"$a"_key; done
            "/etc/ssh/boot/host_rsa_key"
            "/etc/ssh/boot/host_ed25519_key"
          ];
          authorizedKeys = cfg.keys;
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
        cfg.bootDisks);
  };
}
