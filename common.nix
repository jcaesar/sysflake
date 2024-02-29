{
  pkgs,
  enableHM,
  ...
}: {
  imports = [
    enableHM
    ./base.nix
  ];
  home-manager.users.julius = import ./home.nix;

  boot.binfmt.emulatedSystems = ["aarch64-linux" "wasm32-wasi" "wasm64-wasi"];
  systemd.oomd.enableUserSlices = true;

  fonts.packages = with pkgs; [
    ipafont
    ipaexfont
    hanazono
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    (nerdfonts.override {fonts = ["FiraCode" "DroidSansMono" "Terminus"];})
    iosevka
    sarasa-gothic
    source-code-pro
    terminus_font
    inconsolata
    "${wine}/share/wine/fonts"
  ];

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
      (pkgs.callPackage ./pkgs/cyrly.nix {})
    ];
    shell = pkgs.nushellFull;
    password = "";
  };
}
