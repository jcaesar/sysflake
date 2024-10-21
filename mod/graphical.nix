{
  pkgs,
  lib,
  config,
  ...
}: {
  njx."firefox/default" = true;

  services.logind.powerKey = "suspend";

  nix = {
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
  };

  fonts.packages = with pkgs;
    [
      ipafont
      ipaexfont
      hanazono
      noto-fonts
      noto-fonts-cjk-sans
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
    ]
    ++ lib.optional config.njx.work "${wine64}/share/wine/fonts";

  services.xserver = {
    xkb = {
      layout = "us";
      options = "compose:caps";
      variant = "altgr-intl";
    };
    extraConfig = ''
      Section "ServerFlags"
        Option "MaxClients" "2048"
      EndSection
    '';
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-anthy
      fcitx5-gtk
    ];
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    #jack.enable = true;
    wireplumber.enable = true;
  };
  hardware.pulseaudio.enable = false;

  environment.systemPackages = with pkgs; [
    glxinfo
  ];

  users.users.julius.packages = with pkgs; [
    xpra
    mpv
    yt-dlp
    vlc # better windows media player
    helvum # pipewire patch bay
    pulseaudio
    pavucontrol
    dunst # better du
    gomuks # better element
    activitywatch
    sxiv # better feh
    zathura
    imagemagick
    libreoffice
    gimp
    xclip
    polaris-fuse
    dolphin # better explorer.exe
    asak # "better audacity" / just an audio recorder
    gnome-clocks
    easyeffects # pipewire remixer
    omekasy # unicode font style changer
    # Hyprland stuff
    #qt6-wayland
    wofi # worse rofi
    hyprpaper
    hyprlock
    swayidle
    waybar
    alacritty
    polkit-kde-agent
    brightnessctl
  ];

  system.systemBuilderCommands = let
    # reproduce nonexposed envs from nixos/modules/hardware/opengl.nix
    cfg = config.hardware.graphics;
    package = pkgs.buildEnv {
      name = "opengl-drivers";
      paths = [cfg.package] ++ cfg.extraPackages;
    };
  in ''
    mkdir -p $out/opengl
    ln -s ${package} $out/opengl/driver
  '';
  systemd.tmpfiles.rules = [
    "L+ /run/opengl-driver - - - - /run/booted-system/opengl/driver"
  ];

  # Anti-oom-measures pt 2 (press SysRq+Alt+f)
  boot.kernel.sysctl."kernel.sysrq" = let
    all = 1;
    log = 2; # enable control of console logging level
    sak = 4; # enable control of keyboard (SAK, unraw)
    dmp = 8; # enable debugging dumps of processes etc.
    syn = 16; # enable sync command
    mro = 32; # enable remount read-only
    sig = 64; # enable signalling of processes (term, kill, oom-kill)
    off = 128; # allow reboot/poweroff
    rtt = 256; # allow nicing of all RT tasks
  in
    lib.fold lib.bitOr 0 [log sak syn mro sig off];
}
