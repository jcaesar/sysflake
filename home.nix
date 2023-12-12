(import ./shell.nix)
// {
  home.username = "julius";
  home.homeDirectory = "/home/julius";
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;
  programs.command-not-found.enable = true;
}
