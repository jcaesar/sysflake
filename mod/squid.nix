{pkgs, ...}: {
  nixpkgs.config.permittedInsecurePackages = [
    "squid-6.8"
  ];
  services.squid = {
    enable = true;
    configText = ''
      # Needs to contain a few lines like
      #cache_peer oym3.proxy.nic.fujitsu.com parent 8080 0 no-query no-digest carp login=user:pw name=oym3
      include /etc/secrets/squid

      # nixos lube
      # Application logs to syslog, access and store logs have specific files
      cache_log       syslog
      access_log      stdio:/var/log/squid/access.log
      cache_store_log stdio:/var/log/squid/store.log
      # Required by systemd service
      pid_filename    /run/squid.pid
      # Run as user and group squid
      cache_effective_user squid squid
      # Leave coredumps in the first cache dir                                                    71 access_log      stdio:/var/log/squid/access.log
      coredump_dir /var/cache/squid   
      
      acl update_servers dstdomain .ubuntu.com .debian.org .centos.org .ubuntulinux.jp .vinelinux.org .maven.org .maven.apache.org .fedoraproject.org .mozilla.org ftp.iij.ad.jp registry.npmjs.org static.rust-lang.org .crates.io ftp.tsukuba.wide.ad.jp .mirror.pkgbuild.com
      acl direct dstdomain capri .local localhost .fujitsu.co.jp 127.0.0.25 shamo0 shamo1 shamo2 shamo3 shamo4 shamo5 shamo6 shamo7 192.168.0.0/16
      acl nondirect dstdomain fujitsu.com
      acl nope dstdomain facebook.com www.facebook.com fbcdn.net
      acl apache dstdomain .apache.org
      always_direct deny nondirect
      always_direct allow direct
      always_direct allow update_servers
      never_direct allow all
      acl localhosta src 127.0.0.0/8 ::1
      acl vmnet src 172.18.147.0/24
      acl docker src 172.17.0.0/15 10.0.2.15
      acl vbox src 192.168.56.0/24
      acl minikube src 192.168.49.0/24
      acl localstub src 10.13.24.255
      acl shamo_local src 192.168.0.0/28
      acl smpt port 25
      http_access deny smpt
      http_access deny nope
      http_access deny to_localhost
      http_access allow localhosta
      http_access allow localstub
      http_access allow minikube
      http_access allow vmnet
      http_access allow docker
      http_access allow vbox
      http_access allow shamo_local
      http_access deny all
      http_port 3128
      #visible_hostname master
      #debug_options ALL,1 11,3 20,3

      # cache conf
      #hierarchy_stoplist cgi-bin ?
      cache_mem 128 MB
      cache_dir diskd /var/cache/squid 10960 2 8
      maximum_object_size 5120 MB
      refresh_pattern ^ftp: 1440 20% 10080
      refresh_pattern ^gopher: 1440 0% 1440
      refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
      refresh_pattern . 0 20% 4320
      refresh_pattern .deb$ 1577846 100% 1577846
      refresh_pattern .rpm$ 1577846 100% 1577846
      refresh_pattern .pkg.tar.xz$ 1577846 100% 1577846
      refresh_pattern Packages.gz$ 1440 50% 2880
      quick_abort_min -1 QB
      read_ahead_gap 1 MB

      max_filedescriptors 8192

      # shut up netdata
      acl acclogexclude1 url_regex ^cache_object://localhost/counters$
      acl acclogexclude2 url_regex shamo.*/jobs/
      acl acclogexclude3 url_regex stratus.*\.stratus\..*/(jobs|datasources)/
      acl acclogexclude any-of acclogexclude1 acclogexclude2 acclogexclude3
      access_log none acclogexclude
      access_log syslog:debug squid

      #debug_options 28,3 # debug acl
      shutdown_lifetime 3 seconds
      forwarded_for off
    '';
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
