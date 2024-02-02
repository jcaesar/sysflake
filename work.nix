rec {
  shamo = rec {
    all = builtins.genList (x: x) 8;
    each = f: map f all;
    nixed = [2 6 7];
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
  # Escaping fun: If you were to use an email address as user name, nix doesn't quite handle that correctly, and you need to overwrite.
  #systemd.services.nix-daemon.environment =
  #  let p = "http://michaelis%%40jp.fujitsu.com:0123456789@10.128.145.88:8080/";
  #  in lib.mkForce { http_proxy = p; https_proxy = p; all_proxy = p; ftp_proxy = p; };
  proxy = user: pw: "http://${user}:${pw}@10.128.145.88:8080/";
  config = {lib, ...}: {
    boot.loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 15;
        #editor = false;
      };
      efi.canTouchEfiVariables = false;
    };
    networking.proxy.noProxy = noProxy;
    networking.extraHosts = ''
      10.38.90.22 capri
      ${lib.concatStringsSep "\n" (shamo.each (x: "${shamo.ip x} ${shamo.name x}"))}
    '';
    time.timeZone = "Asia/Tokyo";
    i18n.defaultLocale = "en_US.UTF-8";
    nix.settings.experimental-features = ["nix-command" "flakes"];
    networking.firewall.enable = true;
    security.sudo.wheelNeedsPassword = false;
    networking.nameservers = ["10.0.238.1" "10.0.238.70"];
    networking.useNetworkd = true;
    boot.initrd.systemd.network.enable = true; # Not sure if necessary or effectful
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
      settings.PermitRootLogin = "prohibit-password";
      settings.ListenAddress = "0.0.0.0:2222";
    };
    virtualisation.docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };
}
