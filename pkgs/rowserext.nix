pkgs: let
  src = pkgs.fetchFromGitHub {
    owner = "jcaesar";
    repo = "rowserext";
    rev = "f8a1cfbcc7e5376c65bce31c0204b93243b949ec";
    hash = "sha256-H4LV2t2kjAb4YvIOR8RqryMKvhWxjMi/16Nkhu7Ny/o=";
  };
in
  pkgs.callPackage src {}
