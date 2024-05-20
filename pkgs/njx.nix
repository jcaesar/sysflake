pkgs:
pkgs.python3.pkgs.callPackage (pkgs.fetchFromGitHub {
  owner = "jcaesar";
  repo = "njx";
  rev = "65e65451b5b2604582674ae7e64807d8e8ee4726";
  hash = "sha256-CfXNzz/zevOmn1s6ah051TGknWQzFa2jJPwYTMCzELE=";
}) {}
