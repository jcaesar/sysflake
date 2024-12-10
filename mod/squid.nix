{pkgs, ...}: {
  nixpkgs.config.permittedInsecurePackages = [
    "squid-6.10"
  ];
  njx.manual.squid = ''
    Make sure that `/etc/secrets/squid` contains at least one line like
    ```
    cache_peer oym3.proxy.nic.… parent 8080 0 no-query no-digest carp login=user:pw name=oym3
    ```
  '';
  services.squid = {
    enable = true;
    configText = builtins.readFile ./squid.conf;
  };
  systemd.services.squid.serviceConfig.ExecStartPre = ''${pkgs.bash}/bin/bash -c "mkdir -p /var/cache/squid && chown squid:squid /var/cache/squid"'';

  networking.firewall = let
    extraRules = sign: ''
      iptables -${sign} INPUT -p tcp -i docker0 -m tcp --dport 3128 -j ACCEPT
    '';
  in {
    extraCommands = extraRules "A";
    extraStopCommands = extraRules "D";
  };
}
