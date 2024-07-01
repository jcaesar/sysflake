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
    languages = {
      language = [
        {
          name = "nix";
          language-servers = ["nixd"];
        }
      ];
      language-server.nixd.command = "${pkgs.nixd}/bin/nixd";
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

  # Stolen from https://wiki.nixos.org/wiki/Nushell
  programs = {
    nushell = {
      enable = true;
      package = pkgs.nushellFull;
      configFile.source = ../dot/config.nu;
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
        scan_timeout = 5;
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };
        aws.disabled = true;
        directory.truncate_to_repo = false;
        nix_shell.heuristic = true;
        hostname.ssh_only = false;
      };
    };
    zoxide = {
      enable = true;
      enableNushellIntegration = true;
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

  wayland.windowManager.hyprland = {
    settings = import ../dot/hypr/hyprland.nix;
    xwayland.enable = true;
  };

  home.file.".config/git/config".source = ../dot/git/config;
  home.file.".config/i3/config".source = ../dot/i3/config;
  home.file.".config/hypr/hyprlock.conf".source = ../dot/hypr/hyprlock.conf;
  home.file.".config/alacritty/alacritty.toml".source = ../dot/alacritty.toml;
  home.file.".config/mpv/mpv.conf".source = ../dot/mpv/mpv.conf;
  home.file.".config/mpv/input.conf".source = ../dot/mpv/input.conf;
  home.file.".gdbinit".source = ../dot/gdbinit;
}
