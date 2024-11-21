{
  pkgs,
  lib,
  ...
}: let
  inherit (lib) concatStrings reverseList;
  un = x: concatStrings (reverseList x);
  # make sure this doesn't appear in google
  sof = un ["ps" "a" "tr"];
  prod = un ["tex" "re" "co"];
  env = pkgs.buildFHSEnv {
    name = "install-env";
    targetPkgs = pkgs: [
      pkgs.coreutils
      pkgs.openssl
      pkgs.getopt
      pkgs.bash
      pkgs.iptables
      pkgs.systemd
      pkgs.procps
    ];
  };
in {
  boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_6_1;
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [openssl];
  security.pki.certificateFiles = [
    (pkgs.fetchurl {
      url = "https://certs.godaddy.com/repository/gdroot-g2.crt";
      hash = "sha256-UAMpq6wQCpU6c5a1Sza+V9MzAi8XQBvJSCSOoXnPF4Q=";
    })
    (pkgs.fetchurl {
      url = "https://certs.godaddy.com/repository/gd-class2-root.crt";
      hash = "sha256-R/FaUqmEqx+c2StsGEnARlwbPJxoN9VOXSwAT6Ababc=";
    })
  ];
  njx.manual.pua = ''
    unar *_deb.tar.gz # 8_3_100
    install -D *_deb/*conf /etc/pa""nw
    unar *_deb/*.deb
    unar c*/data.tar
    unar data/opt/*/*/*.tar.gz
    mv *agent* /opt/${sof}
  '';
  systemd.services.${"${sof}_pm${""}d"} = {
    after = ["local-fs.target" "network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      BindReadOnly = ["${env.fhsenv}/usr/bin:/bin"];
      ExecStart = "/opt/${sof}/bin/pmd";
      ExecStopPost = "/opt/${sof}/k${""}m_utils/k${""}m_manage stop";
      Restart = "always";
    };
  };
  users.users.${"${prod}user"} = {
    isSystemUser = true;
    group = "${prod}user";
  };
  users.groups.${"${prod}user"} = {};
}
