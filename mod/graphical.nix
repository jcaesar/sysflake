{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./firefox
  ];
  services.logind.powerKey = "suspend";

  nix = {
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
  };

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
    "${wine64}/share/wine/fonts"
  ];

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
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-anthy
      fcitx5-gtk
    ];
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
  hardware.pulseaudio.enable = false;

  environment.systemPackages = with pkgs; [
    glxinfo
  ];

  users.users.julius.packages = with pkgs; [
    xpra
    mpv
    yt-dlp
    vlc
    helvum
    pulseaudio
    pavucontrol
    dunst
    gomuks
    activitywatch
    sxiv
    barrier
    imagemagick
    libreoffice
    gimp
    xclip
    polaris-fuse
    dolphin
    # Hyprland stuff
    #qt6-wayland
    wofi
    swww
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
    cfg = config.hardware.opengl;
    package = pkgs.buildEnv {
      name = "opengl-drivers";
      paths = [cfg.package] ++ cfg.extraPackages;
    };
    package32 = pkgs.buildEnv {
      name = "opengl-drivers-32bit";
      paths = [cfg.package32] ++ cfg.extraPackages32;
    };
  in
    ''
      mkdir -p $out/opengl
      ln -s ${package} $out/opengl/driver
    ''
    + lib.optionalString cfg.driSupport32Bit ''
      ln -s ${package32} $out/opengl/driver32
    '';
  systemd.tmpfiles.rules =
    [
      "L+ /run/opengl-driver - - - - /run/booted-system/opengl/driver"
    ]
    ++ lib.optionals config.hardware.opengl.driSupport32Bit [
      "L+ /run/opengl-driver-32 - - - - /run/booted-system/opengl/driver-32"
    ];
}
