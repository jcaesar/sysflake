{pkgs, ...}: {
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

  users.users.julius.packages = with pkgs; [
    xpra
    firefox
    mpv
    vlc
    helvum
    pulseaudio
    pavucontrol
    dunst
    gomuks
    #activitywatch
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
  ];
}
