{
  config,
  lib,
  pkgs,
  ...
}: {
  # Use the systemd-boot EFI boot loader.
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
  nix.settings.experimental-features = ["nix-command" "flakes"];
  services.smartd.enable = true;
  services.smartd.notifications.wall.enable = true;

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

  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    #jack.enable = true;
    wireplumber.enable = true;
  };

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
    smartmontools
    alejandra
    efibootmgr
    openssl
    pwgen
    nvd
  ];

  users.users.julius = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    #openssh.authorizedKeys.keys = common.sshKeys.client;
    packages = with pkgs; [
      fish
      nushell
      helix
      git
      gh
      firefox
      mpv
      helvum
      pulseaudio
      pavucontrol
      dunst
      gomuks
      activitywatch
      sxiv
      barrier
      jetbrains.idea-community
      imagemagick
      libreoffice
      xclip
      # Hyprland stuff
      #qt6-wayland
      wofi
      swww
      hyprpaper
      polkit-kde-agent
      file
      unar
      delta
      difftastic
      sshfs
    ];
    shell = pkgs.nushell;
    password = "";
  };

  # nix shell --print-build-logs .#nixosConfigurations.$host.config.system.build.vm -c run-korsika-vm
  # Switch to serial0 console from qemu viewer
  services.getty.autologinUser =
    if config.virtualisation ? mountHostNixStore
    then "root"
    else null;
}
