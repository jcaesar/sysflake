{flakes, ...}: let
  common = import ../work.nix;
in {
  imports = [flakes.wsl.nixosModules.wsl];
  wsl.enable = true;
  njx.work = true;
  boot.loader.systemd-boot.enable = false;

  users.users.root.openssh.authorizedKeys.keys = common.sshKeys.strong;

  system.stateVersion = "24.05";
}
