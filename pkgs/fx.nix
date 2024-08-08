{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule {
  pname = "fx";
  version = "35.0.0";
  src = fetchFromGitHub {
    owner = "antonmedv";
    repo = "fx";
    rev = "35.0.0";
    hash = "sha256-EirlA/gcW77UP9I4pVCjjG3pSYnCPw+idX9YS1izEpY=";
  };
  vendorHash = "sha256-h9BUL7b8rNmhVxmXL3CBF39WSkX+8eS2M9NDJhbPI0o=";
}
