{lib, ...}: let
  private = import ./private.nix;
in {
  networking.hostName = "doggieworld";
  security.acme = {
    defaults.email = "letsencrypt-doggieworld@liftm.de";
    acceptTerms = true;
  };
  imports = [
    ../common.nix
    ./grafana.nix
    ./networking.nix
    ./do.nix
  ];
  services.dante = {
    enable = true;
    config = lib.readFile ./danted.conf;
  };
  services.knot = {
    enable = true;
    settingsFile = ./knot.conf;
    keyFiles = ["/etc/secrets/knot-doggieworld-key.conf"];
  };
  services.coturn = {
    enable = true;
    static-auth-secret-file = "/etc/secrets/coturn-static-auth-secret";
    extraConfig = lib.readFile ./turnserver.conf; # nixpkgs doesn't know about many of teh setting I use. TODO pr
  };
  services.prometheus = import ./prometheus.nix;
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = private.terminalKeys;
  system.stateVersion = "24.05";
}
