{
  pkgs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nixpkgs.overlays = [(final: _: import ../pkgs final)];
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
    helix
    pv
    jq
    rq
    wget
    httpie
    git
    screen
    tmux
    lls
    htop
    zenith-nvidia
    iftop
    iotop
    logcheck
    direnv
    nload
    ripgrep
    fd
    du-dust
    smartmontools
    alejandra
    efibootmgr
    openssl
    nvd
    nix-diff
    miniserve
    inotify-tools
    vulnix
    tcpdump
    lshw
    cyme # better lsusb
    (import ../pkgs/njx.nix pkgs)
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
}
