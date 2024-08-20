{
  pkgs,
  lib,
  flakes,
  system,
  ...
}: {
  nix.registry.n.flake = flakes.nixpkgs;
  nix.registry.sf.flake = flakes.self;
  nix.nixPath = ["nixpkgs=${flakes.nixpkgs}"];
  nix.channel.enable = false;
  system.configurationRevision =
    flakes.self.rev or flakes.self.dirtyRev or "nogit";
  system.nixos.version = let
    r = flakes.self.shortRev or flakes.self.dirtyShortRev or "nogit";
  in "j_${r}_${flakes.self.lastModifiedDate}";
  environment.etc = let
    mkLnk = name: flake: {
      name = "sysflake/${name}";
      value.source = flake;
    };
  in
    lib.mapAttrs' mkLnk flakes;

  nixpkgs.overlays = [(_: _: flakes.self.packages.${system})];
  nix.settings.experimental-features = ["nix-command" "flakes" "repl-flake"];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 15;
      editor = false;
    };
    efi.canTouchEfiVariables = true;
  };
  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "en_US.UTF-8";
  services.smartd.enable = lib.mkDefault true;
  services.smartd.notifications.wall.enable = true;
  networking.networkmanager.enable = false;

  environment.systemPackages = with pkgs; [
    vim
    pv
    jq
    rq
    wget
    httpie # better wget/curl
    xh # "better" httpie
    screen
    tmux # better screen
    lls # better ss -loptun
    direnv
    nload
    ripgrep # better grep -R
    fd # better find
    htop # better top
    zenith-nvidia # combined htop/nload/iotop
    du-dust # better du
    iftop
    iotop
    smartmontools
    efibootmgr
    openssl
    nvd
    nix-diff
    miniserve # better python -m http.server
    inotify-tools
    tcpdump
    lshw
    cyme # better lsusb
    libtree # better ldd
    njx
    helix # better vim
    git # better svn/hg
    rsync # better scp
  ];

  services.openssh = {
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = lib.mkForce "prohibit-password";
    openFirewall = true;
    ports = lib.mkDefault [2222];
  };
  networking.firewall.allowedTCPPorts = [9418 1337];
  networking.useDHCP = lib.mkDefault false;

  services.xserver.displayManager.gdm.autoSuspend = false;

  zramSwap = lib.mkDefault {
    enable = true;
    memoryMax = 8 * 1024 * 1024 * 1024;
    memoryPercent = 30;
  };

  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];
}
