{
  pkgs,
  lib,
  ...
}: let
  inherit (import ../work.nix) shamo noProxy;
in {
  njx.base = true;
  networking.proxy.noProxy = noProxy;
  networking.extraHosts = ''
    10.38.90.22 capri
    ${lib.concatStringsSep "\n" (shamo.each (x: "${shamo.ip x} ${shamo.name x}"))}
  '';
  boot.initrd.systemd.network.enable = true; # Not sure if necessary or effectful
  networking.firewall.enable = true;
  services.openssh.enable = true;
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
  environment.systemPackages = with pkgs; [
    vim
    helix
    nil
    pv
    jq
    rq
    wget
    httpie
    git
    screen
    tmux
    rxvt-unicode
    lls
    htop
    bottom
    iotop
    logcheck
    direnv
  ];
}
