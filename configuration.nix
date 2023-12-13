# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./networking.nix
  ];

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
  #security.sudo.wheelNeedsPassword = false;
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "prohibit-password";
    settings.ListenAddress = "0.0.0.0:2222";
  };
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
  services.smartd.enable = true;
  services.smartd.notifications.wall.enable = true;

  networking.hostName = "korsika";

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      options = "compose:caps";
      variant = "altgr-intl";
    };
    desktopManager = {
      xterm.enable = false;
    };
    displayManager = {
      defaultSession = "none+i3";
    };
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        rofi
        alacritty
        rxvt-unicode
        i3status
        i3lock
      ];
    };
  };
  fonts.packages = with pkgs; [
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

  environment.etc."xsg/user-dirs.defaults".text = ''
    XDG_DESKTOP_DIR="$HOME/desktop"
    XDG_DOWNLOAD_DIR="$HOME/downloads"
    XDG_TEMPLATES_DIR="$HOME/.config/templates"
    XDG_PUBLICSHARE_DIR="$HOME/public"
    XDG_DOCUMENTS_DIR="$HOME/docs"
    XDG_MUSIC_DIR="$HOME/music"
    XDG_PICTURES_DIR="$HOME/music"
    XDG_VIDEOS_DIR="$HOME/music"
  '';
  environment.variables.EDITOR = "hx";
  environment.variables.VISUAL = "hx";

  #programs.hyprland = {
  #  enable = true;
  #  xwayland.enable = true;
  #  enableNvidiaPatches = true;
  #};
  programs.command-not-found.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    #powerManagement.finegrained = false; # Too old
    open = false; # I wish
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  nixpkgs.config.allowUnfreePredicate = let
    startsWith = pfx: str: lib.removePrefix pfx str != str;
  in
    pkg: startsWith "nvidia-" (lib.getName pkg);
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  services.xserver.videoDrivers = ["nvidia"];

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
      # Hyprland stuff
      #qt6-wayland
      wofi
      swww
      hyprpaper
      polkit-kde-agent
    ];
    shell = pkgs.nushell;
    password = "";
  };
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    #QT_QPA_PLATFORM = "wayland";
    #CLUTTER_BACKEND = "wayland";
    #SDL_VIDEODRIVER = "wayland";
    #MOZ_ENABLE_WAYLAND = "1";
    #MOZ_WEBRENDER = "1";
    #XDG_SESSION_TYPE = "wayland";
    #XDG_CURRENT_DESKTOP = "sway";
    #QT_QPA_PLATFORMTHEME = "qt5ct";
    #GLFW_IM_MODULE = "fcitx";
    #GTK_IM_MODULE = "fcitx";
    #INPUT_METHOD = "fcitx";
    #XMODIFIERS = "@im=fcitx";
    #IMSETTINGS_MODULE = "fcitx";
    #QT_IM_MODULE = "fcitx";
  };
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-anthy
      fcitx5-gtk
    ];
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
    iotop
    logcheck
    direnv
    nload
    ripgrep
    fd
    smartmontools
    alejandra
  ];

  #system.copySystemConfiguration = true;

  system.stateVersion = "24.05";
}
