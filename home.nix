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
      extraConfig = builtins.readFile ./config.nu;
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
}
