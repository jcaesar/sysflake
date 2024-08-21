{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (import ../work.nix) shamo noProxy;
in {
  njx.base = true;
  njx.docker = config.njx.common;
  networking.proxy.noProxy = noProxy;
  networking.extraHosts = ''
    10.38.90.22 capri
    ${lib.concatStringsSep "\n" (shamo.each (x: "${shamo.ip x} ${shamo.name x}"))}
  '';
  boot.initrd.systemd.network.enable = true; # Not sure if necessary or effectful
  networking.firewall.enable = true;
  services.openssh.enable = true;
  environment.systemPackages =
    (with pkgs; [
      rxvt-unicode
      bottom
      logcheck
    ])
    ++ lib.optionals config.njx.common (with pkgs; [
      nil
      jdt-language-server
      kcat
      maven
      openjdk11
      openjdk17
    ]);
}
