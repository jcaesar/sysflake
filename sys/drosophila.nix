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
      openjdk11
      kcat
    ];
  };
  systemd.network = {
    enable = true;
    networks."10-wired" = {
      matchConfig.Name = ["en*"];
      DHCP = "yes";
    };
  };

  system.build.createScript = pkgs.writeScriptBin "create-${name}-instance" ''
    #!${lib.getExe pkgs.nushell}

    nix eval ${sysflake}#nixosConfigurations.${name}.config.system.build.toplevel.drvPath

    let nixorg = 427812963091

    let ami = (${lib.getExe pkgs.awscli} ec2 describe-images --owners $nixorg
        --filter 'Name=name,Values=nixos/${lib.trivial.release}*'
        --filter 'Name=architecture,Values=x86_64'
      | from json | get Images | sort-by -r CreationDate).0.ImageId

    let vols = [{DeviceName:/dev/xvda,Ebs:{VolumeType:gp3,VolumeSize:80,DeleteOnTermination:true}}];

    (
      ${lib.getExe pkgs.awscli} ec2 run-instances
        --image-id $ami
        --count 1 --instance-type m5a.xlarge
        --subnet-id subnet-00c8ce36439b1b7d8
        --security-group-ids sg-0e93028f51a4617c2
        --instance-initiated-shutdown-behavior terminate
        --block-device-mappings ($vols | to json)
        --key-name mic-korsika
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=mic-${name}}]'
        --user-data file://${config.system.build.deployScript}
    )
  '';

  system.build.deployScript = pkgs.writeScript "become-${name}" ''
    #!/usr/bin/env bash
    mkdir -p ~/.ssh
    ${lib.concatStringsSep "\n" (map (k: "echo '${k}' >~/.ssh/authorized_keys") common.sshKeys.strong)}
    nixos-rebuild boot --flake ${sysflake}#${name} --verbose
    touch /root/.deployed
    systemctl reboot
  '';
  virtualisation.amazon-init.enable = false;
}
