{
  pkgs,
  lib,
  modulesPath,
  config,
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
    cyme # better lsusb
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

  environment.etc."sysflake/installed.json".source = let
    inherit (builtins) filter genericClosure toJSON attrValues;
    inherit (lib.lists) flatten unique;
    pkgListEx =
      config.environment.systemPackages
      ++ flatten (map (u: u.packages or []) (attrValues config.users.users));
    key = map (p: {
      key = p.name;
      val = p;
    });
    pkgList = genericClosure {
      startSet = key pkgListEx;
      operator = item:
        key (flatten (map (k: item.val.${k} or []) [
          "propagatedBuildInputs"
          "depsTargetTarget"
          "depsTargetTargetPropagated"
        ]));
    };
    attrs = pkg: {inherit (pkg.val) pname version;};
    hasPname = pkg: pkg.val ? pname;
    info = unique (map attrs (filter hasPname pkgList));
    json = pkgs.writeText "installed.json" (toJSON info);
  in
    json;
}
