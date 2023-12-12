{
  system,
  nixpkgs,
  home-manager,
  ...
}: let
  username = "julius";
  homeDirectory = "/home/${username}";
  configHome = "${homeDirectory}/.config";

  pkgs = import nixpkgs {
    inherit system;
    config.xdg.configHome = configHome;
  };

  shell = import ./shell.nix;
in
  shell
  // {
    programs.home-manager.enable = true;
    programs.command-not-found.enable = true;
    xdg = {inherit configHome;};

    home = {
      inherit username homeDirectory;
      stateVersion = "23.11";
    };
  }
