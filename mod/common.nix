{pkgs, ...}: {
  njx.base = true;
  njx.binfmt = true;

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
      vim
      fish
      helix
      gh
      git # better svn/hg
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
      bat # better cat
      urlencode
      nmap
      dos2unix
      dnsutils
      tokei # better cloc
      cyrly
      qemu_kvm
      alejandra
      nixfmt-rfc-style
      nix-update
      nix-tree
      nix-top
      nix-output-monitor # better nix build
      nixpkgs-review
      cargo
      rustc
      cargo-watch
      cargo-edit
      python3.pkgs.python-fx
      rusti-cal # rustier cal
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
