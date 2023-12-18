{pkgs, ...}: rec {
  home.username = "julius";
  home.homeDirectory = "/home/julius";
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;

  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      theme = "gruvbox";
      editor = {
        auto-pairs = false;
        auto-completion = false;
        auto-save = true;
        bufferline = "multiple";
        true-color = true;
        lsp.display-messages = true;
      };
      keys.normal = {
        "C-s" = "split_selection_on_newline";
      };
    };
    extraPackages = with pkgs; [
      dhall-lsp-server
      rust-analyzer
      libclang
      bear
      metals
      gopls
      gleam
      zls
      vhdl-ls
    ];
  };

  # Stolen from https://nixos.wiki/wiki/Nushell
  programs = {
    nushell = {
      enable = true;
      extraConfig = builtins.readFile ./dot/config.nu;
      shellAliases = {
        vi = "hx";
        vim = "hx";
        nano = "hx";
      };
    };
    starship = {
      enable = true;
      enableNushellIntegration = true;
      settings = {
        add_newline = true;
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };
      };
    };
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = false;
    desktop = "${home.homeDirectory}/.local/xdg/desktop";
    documents = "${home.homeDirectory}/docs";
    download = "${home.homeDirectory}/downloads";
    music = "${home.homeDirectory}/music";
    pictures = "${home.homeDirectory}/.local/xdg/pics";
    publicShare = "${home.homeDirectory}/.local/xdg/share";
    templates = "${home.homeDirectory}/.local/xdg/templates";
    videos = "${home.homeDirectory}/music";

    #extraConfig = ''
    #  {
    #    XDG_PROJECTS_DIR = "${home.homeDirectory}/code";
    #    XDG_GAMES_DIR = "${home.homeDirectory}/games";
    #  }
    #'';
  };

  home.file.".config/git/config".source = ./dot/git/config;
  home.file.".config/i3/config".source = ./dot/i3/config;
  home.file.".config/hypr/hyprland.conf".source = ./dot/hypr/hyprland.conf;
  home.file.".config/mpv/mpv.conf".source = ./dot/mpv/mpv.conf;
  home.file.".config/mpv/input.conf".source = ./dot/mpv/input.conf;
  home.file.".gdbinit".source = ./dot/gdbinit;
}
