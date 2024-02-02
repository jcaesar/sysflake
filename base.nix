{
  pkgs,
  config,
  lib,
  ...
}: {
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
    bottom
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
  ];

  # nix shell --print-build-logs .#nixosConfigurations.$host.config.system.build.vm -c run-korsika-vm
  # Switch to serial0 console from qemu viewer
  services.getty.autologinUser =
    if config.virtualisation ? mountHostNixStore
    then "root"
    else null;
}
