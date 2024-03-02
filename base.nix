{
  pkgs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

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
  ];

  services.openssh = {
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = lib.mkForce "prohibit-password";
    openFirewall = true;
    listenAddresses = lib.mkDefault [{
      port = 2222;
      addr = "0.0.0.0";
    }];
  };
  networking.firewall.allowedTCPPorts = [2222 9418 1337];
}
