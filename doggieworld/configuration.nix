{...}: {
  networking.hostName = "doggieworld";
  security.acme = {
    defaults.email = "letsencrypt-doggieworld@liftm.de";
    acceptTerms = true;
  };
  imports = [
    ../common.nix
    ./prometheus.nix
    ./grafana.nix
    ./networking.nix
  ];
  system.stateVersion = "24.05";
}
