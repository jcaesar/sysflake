rec {
  shamo = rec {
    all = builtins.genList (x: x) 8;
    each = f: map f all;
    nixed = [0 2 4 6 7];
    eachNixed = f: builtins.listToAttrs (map f nixed);
    ip = x: "10.25.211." + toString (84 - x);
    internalIp = x: "192.168.100.${toString (x + 2)}";
    name = x: "shamo" + toString x;
  };
  sshKeys = rec {
    strong = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEl5k7aYexi95LNugqwBZQAk/qmA3bruEYqQqFgSpnXSLDeNX0ZZNa8NekuN+Cf7qm9ZJsWZpKzEOi7C//hZa2E= julius@korsika"
    ];
    client =
      strong
      ++ [
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCFOfuBXwqAurmSh3CsK3JMBWPekby7nOjdcbCtvdp4qwnF3689FKucK4vFIvD+FIqPj2laEe22GSQiFApyg7Aw= julius@PALMAROLA"
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBOyNz4Wu9Nl4bwNujJd6lsTZeQd5K+JVi8ZeCDEdxJu2wxjxq1M5miietFH0Dcnz5u+uVEDskyEHMFH1sGkv1BY= julius@PALMAROLA-WSL"
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPchDcLGPK3aUz7vVmgjqKNI46NqRn/Q4bszuC/+sFFOaUv4eWzWa4RW6z/UtfO2hPihE5Wj/n3i3jhLz9OiUJk= julius@PALMAROLA"
        "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBABbsQEGFP1kR14NUKW/Rb7OQZjFSy9ibAHReIw6+yAYX8iB0WS+zVQ3CKiuEajxcihu1PSN9h4D702cqBjwTYPMzQH9ptsGCM2xoY9e913rxxj7RgvZho38XeowNFhy0g2ucSi2N2T5rQJXjr9QVVyYdluEh5M8TnZr/11UW7Ro4HSujA== puttygen@PALMAROLA"
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNNSNxM0TSVATCXTFinTmy54757P93c7YaesT1X/zIfzar5XwxTj9N0KsjBULgaUChpKKyEvc2DoGdPm2f2/leI= michaelis.g01@ZYPERN"
      ];
    yamaguchi = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDVOTv0bSaC0Bssq0J7m8+u1lUIIXJzsqfKCgIoBoTar4oCKig4wkgV9vp1v6Rfw0DhyOTG1l0Wk/BidUZFgHT/q4lt02ujwAHleP1pxIHkPHD7FgfMPJR1POql0K6CrG9EtnAdJbBz8kMBBjxycWlYtIb unknown"];
    shamo2 = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLN6IOSFfpYCNhM/Qzj02GdHIblSsvV2LtgTUSawvZNapLxdCThhn6BD863/960MOnUThW9IyXf4jmX4eVzyqFI= root@shamo2";
    capriJulius = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBE1JLnsDDWqKMg+cVV9CeUE2kvZCekbQCY7hD2sBvPA+KUpCemeEC9jRPd3njoZZ/Ul515+5fZAJ25/1jZi2dn8= julius@capri";
    aoki = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLHWGalN7iJC6qR4rcWs9ivP8mTSaJ7/ucygi6u83Ca2qEzPA+hi6gwpD4gm9uEIwAhztiMz65Amhtira80buLM= g01\\aoki-hiroaki@twoseams";
    k8sconfig = map (key: "command=\"kubectl config view --flatten\" ${key}") [capriJulius aoki];
  };
  packages = pkgs:
    with pkgs; [
      vim
      helix
      nil
      pv
      jq
      rq
      wget
      httpie
      git
      screen
      tmux
      rxvt-unicode
      lls
      htop
      bottom
      iotop
      logcheck
      direnv
    ];
  noProxy = "127.0.0.1,localhost,fujitsu.co.jp,${builtins.concatStringsSep "," (shamo.each shamo.name)}";
  config = {lib, ...}: {
    networking.proxy.noProxy = noProxy;
    networking.extraHosts = ''
      10.38.90.22 capri
      ${lib.concatStringsSep "\n" (shamo.each (x: "${shamo.ip x} ${shamo.name x}"))}
    '';
    boot.initrd.systemd.network.enable = true; # Not sure if necessary or effectful
    networking.firewall.enable = true;
    services.openssh.enable = true;
    virtualisation.docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };
  dns = ["10.0.238.1" "10.0.238.70"];
  ntp = ["ntp2.css.fujitsu.com" "ntp1.css.fujitsu.com"];
}
