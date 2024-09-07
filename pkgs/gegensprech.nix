{
  fetchFromGitHub,
  callPackage,
}: let
  src = fetchFromGitHub {
    owner = "jcaesar";
    repo = "gegensprech";
    rev = "2492e139a42c516df74e7c9011671e4441fe6295";
    hash = "sha256-wxMGBayFbiiDgv+MUgrW1RKPrfyFXXf326TaJiHXNRU=";
  };
in
  callPackage src {}
