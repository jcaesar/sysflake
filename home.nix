{...}: {
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
  };

  # Stolen from https://nixos.wiki/wiki/Nushell
  programs = {
    nushell = {
      enable = true;
      extraConfig = ''
        let load_direnv = {
          if (which direnv | is-empty) { return }
          direnv export json | from json | default {} | load-env
        }
        $env.config = {
          show_banner: false,
          completions: {
            case_sensitive: false # case-sensitive completions
            quick: true    # set to false to prevent auto-selecting completions
            partial: true    # set to false to prevent partial filling of the prompt
            algorithm: "fuzzy"    # prefix or fuzzy
          }
          hooks: {
            pre_prompt: [{ print -n $"(ansi title)(pwd) $(ansi st)" }]
            pre_execution: [
              { print -n $"(ansi title)(pwd) > (commandline)(ansi st)" }
              load_direnv
            ]
            env_change: {
              PWD: [{|before, after| load_direnv }]
            }
          }
        }
        $env.PATH = (
          $env.PATH |
          split row (char esep) |
          prepend /home/myuser/.apps |
          append /usr/bin/env
        )
      '';
      shellAliases = {
        vi = "hx";
        vim = "hx";
        nano = "hx";
      };
    };

    #carapace.enable = true;
    #carapace.enableNushellIntegration = true;

    starship = {
      enable = true;
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
