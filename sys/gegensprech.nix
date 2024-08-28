{
  pkgs,
  lib,
  ...
}: let
  private = import ../private.nix;
in {
  njx.pi3 = true;
  njx.sshUnlock.keys = private.terminalKeys;
  boot.initrd.systemd.enable = true;
  networking.hostName = "gegensprech";
  networking.supplicant.wlan0.extraConf = "country=JP";
  users.users.root.openssh.authorizedKeys.keys = private.terminalKeys ++ [private.prideKey];
  users.users.gegensprech = {
    isNormalUser = true;
    packages = with pkgs; [gegensprech];
    openssh.authorizedKeys.keys = private.terminalKeys;
  };

  system.stateVersion = "24.05";
}
