{
  pkgs,
  config,
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
    inotify-tools
  ];

  # env $"SHARED_DIR=(pwd)/share" "QEMU_OPTS=-nographic" \
  #  nix shell -vL .#nixosConfigurations.${host}.config.system.build.vm -c run-${host}-vm
  # Replace the -nographic with -display curses if you need the boot log
  services.getty.autologinUser = lib.mkIf (config.virtualisation ? mountHostNixStore) "root";
}
