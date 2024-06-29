{pkgs, ...}: {
  njx.base = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.julius = import ./home.nix;

  systemd.oomd.enableUserSlices = true;

  environment.variables = {
    EDITOR = "hx";
    VISUAL = "hx";
    MINISERVE_PORT = toString 1337;
  };

  environment.systemPackages = with pkgs; [
    deadnix
    nil
  ];

  hardware.opengl = {
    enable = true;
    driSupport = true;
    #driSupport32Bit = true;
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
      cyrly
      qemu_kvm
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
    ];
    shell = pkgs.nushellFull;
    password = "";
  };
}
