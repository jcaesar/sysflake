{pkgs, ...}: {
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
    - Make sure config is in /etc/panw/cortex.conf.
    - TODO install
  '';
}
