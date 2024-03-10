{pkgs, ...}: {
  imports = [
    ./firefox
  ];
  services.logind.powerKey = "suspend";

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
    xclip
    # Hyprland stuff
    #qt6-wayland
    wofi
    swww
    hyprpaper
    polkit-kde-agent
    (pkgs.callPackage ./pkgs/polaris-fuse.nix {})
  ];
}
