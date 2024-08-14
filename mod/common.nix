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
    vulnix
  ];

  hardware.graphics.enable = true;

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
      delta # better diff
      difftastic # much better diff
      glow # cat for markdown
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
      alejandra
      nix-update
      cargo
      rustc
      cargo-watch
      cargo-edit
      python3.pkgs.python-fx
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
    shell = pkgs.nushell;
    password = "";
  };
}
