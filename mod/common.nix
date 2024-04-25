{
  pkgs,
  lib,
  pkgsStable,
  enableHM,
  ...
}: {
  imports = [
    enableHM
    ./base.nix
  ];
  home-manager.users.julius = import ./home.nix;

  systemd.oomd.enableUserSlices = true;

  environment.variables.EDITOR = "hx";
  environment.variables.VISUAL = "hx";

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  users.users.julius = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    #openssh.authorizedKeys.keys = common.sshKeys.client;
    packages = with pkgs; [
      fish
      helix
      git
      gh
      file
      unar
      delta
      difftastic
      sshfs
      wol
      pwgen
      binutils
      binwalk
      bat
      urlencode
      nmap
      dos2unix
      dnsutils
      tokei
      (python3.withPackages (ps:
        with ps; [
          netaddr
          requests
          aiohttp
          tqdm
          matplotlib
          pandas
          numpy
        ]))
      (pkgsStable.callPackage ../pkgs/cyrly.nix {})
    ];
    shell = pkgs.nushellFull;
    password = "";
  };
}
