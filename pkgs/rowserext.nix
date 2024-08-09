{
  fetchFromGitHub,
  callPackage,
}: let
  src = fetchFromGitHub {
    owner = "jcaesar";
    repo = "rowserext";
    rev = "c9fa4453fd964f3bf25eb3c2da7ff7cc36b903bc";
    hash = "sha256-GG64mykdk+cKW0W6fhtnUEVf81qkdeQftzhbdblfdU4=";
  };
in
  callPackage src {}
