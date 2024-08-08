{
  modulesPath,
  pkgs,
  config,
  lib,
  flakes,
  ...
}: let
  common = import ../work.nix;
  name = "drosophila";
  sysflake = "github:jcaesar/sysflake/${flakes.self.rev}";
in {
  imports = ["${modulesPath}/virtualisation/amazon-image.nix"];
  njx.common = true;
  njx.binfmt = false; # takes like 10 minutes to build :(
  njx.work = true;
  networking.hostName = name;
  services.openssh.ports = [22];
  boot.loader.grub.enable = true;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  system.stateVersion = "23.11";
  users.users.julius = {
    extraGroups = ["wheel" "docker"];
    openssh.authorizedKeys.keys = common.sshKeys.client;
    packages = with pkgs; [
      awscli
      k9s
      kubectl
      eksctl
    ];
  };
  systemd.network = {
    enable = true;
    networks."10-wired" = {
      matchConfig.Name = ["en*"];
      DHCP = "yes";
    };
  };
  systemd.timers.stop-loss = {
    timerConfig.OnCalendar = "23:00:00 Asia/Tokyo";
    timerConfig.Unit = "poweroff.target";
    wantedBy = ["timers.target"];
  };
  fileSystems."/home" = {
    device = "/dev/disk/by-label/homedisk";
    fsType = "ext4";
  };
  services.openssh.hostKeys = [
    {
      path = "/home/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];
  systemd.services.serial-htop = {
    wantedBy = ["multi-user.target"];
    serviceConfig.ExecStart = "${lib.getExe' pkgs.expect "unbuffer"} ${lib.getExe pkgs.htop}";
    serviceConfig.StandardOutput = "tty";
    serviceConfig.TTYPath = "/dev/ttyS0";
  };
  systemd.services."serial-getty@ttyS0".enable = lib.mkForce false;

  system.build.createScript = let
    aws = lib.getExe pkgs.awscli;
    instanceSpec = {
      ImageId = "NIXOSAMI";
      InstanceType = "m5a.xlarge";
      KeyName = "mic-korsika";
      MaxCount = 1;
      MinCount = 1;
      SecurityGroupIds = ["sg-0e93028f51a4617c2"];
      SubnetId = "subnet-00c8ce36439b1b7d8";
      UserData = "file://${config.system.build.deployScript}";
      EbsOptimized = true;
      IamInstanceProfile = {Name = "mic-ir-op";};
      InstanceInitiatedShutdownBehavior = "terminate";
      TagSpecifications = [
        {
          ResourceType = "instance";
          Tags = [
            {
              Key = "Name";
              Value = "ephemeral-mic-${name}";
            }
            {
              Key = "documentation";
              Value = ''
                Machine is ephemeral and slated to auto-delete on TOMORROW.
                If it is running after that date, feel free to terminate it and notify Julius.
              '';
            }
          ];
        }
      ];
      BlockDeviceMappings = [
        {
          DeviceName = "/dev/xvda";
          Ebs = {
            VolumeType = "gp3";
            VolumeSize = 50;
            DeleteOnTermination = true;
          };
        }
      ];
      NetworkInterfaces = [
        {
          DeviceIndex = 0;
          AssociatePublicIpAddress = false;
        }
      ];
    };
    instanceFile = pkgs.writeText "spec.json" (builtins.toJSON instanceSpec);
  in
    pkgs.writeScriptBin "create-${name}-instance" ''
      #!${lib.getExe pkgs.nushell}

      nix eval ${sysflake}#nixosConfigurations.${name}.config.system.build.toplevel.drvPath

      let nixorg = 427812963091

      let ami = (${aws} ec2 describe-images --owners $nixorg
          --filter 'Name=name,Values=nixos/${lib.trivial.release}*'
          --filter 'Name=architecture,Values=x86_64'
        | from json | get Images | sort-by -r CreationDate).0.ImageId

      let spec = sed $"s/TOMORROW/((date now) + 1day | format date "%Y-%m-%d")/; s/NIXOSAMI/($ami)/;" ${instanceFile} # meh
      let insts = (${aws} ec2 run-instances --cli-input-json ($spec) | from json);

      $insts.Instances | cat
      let id = ($insts.Instances.0.InstanceId)
      echo $id
      ${aws} ec2 wait instance-running --instance-ids $id
      # volume precreated
      # aws ec2 create-volume --availability-zone ap-northeast-1a --size 60 --volume-type gp3
      # (az matches subnet)
      # mkfs.ext4 -L homedisk /dev/xvdb
      ${aws} ec2 attach-volume --volume-id vol-0a71f75ff89e3d034 --instance-id $id --device /dev/xvdb
      ${aws} ec2 associate-address --instance-id $id --allocation-id eipalloc-0b6b1834ec4953923
    '';

  system.build.deployScript = pkgs.writeScript "become-${name}" ''
    #!/usr/bin/env bash
    mkdir -p ~/.ssh
    ${lib.concatStringsSep "\n" (map (k: "echo '${k}' >~/.ssh/authorized_keys") common.sshKeys.strong)}
    rm -rf /etc/nixos
    nixos-rebuild boot --flake ${sysflake}#${name} --verbose
    mount /dev/xvdb /home
    rm /home/julius/.local/state/nix/profiles/home-manager*
    rm /home/julius/.local/state/home-manager/gcroots/current-home
    systemctl reboot
  '';
  virtualisation.amazon-init.enable = false;

  boot.initrd.services.resolved.enable = lib.mkDefault false;
}
