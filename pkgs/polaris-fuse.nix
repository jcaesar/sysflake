{
  rustPlatform,
  fetchFromGitHub,
  fuse3,
  pkg-config,
  lib,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "polaris-fuse";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "jcaesar";
    repo = "${pname}";
    rev = "f0d42d22f0bb2491174fc0775393a9e2c0b58a6a";
    hash = "sha256-SNa+/24jrZ2e1njg+BPR3kPtIQKMR7ll+UAjvY+qEk8=";
  };
  cargoSha256 = "sha256-s6kUMxXmhAtf88olllNWjgL0+kEnvtbVry+C60T+0Bk=";

  nativeBuildInputs = [pkg-config];
  PKG_CONFIG_PATH = "${fuse3}/lib/pkgconfig";

  meta = with lib; {
    description = "Mount polaris servers as fuse folders";
    license = licenses.mit;
    platforms = platforms.linux;
    homepage = "https://github.com/jcaesar/${pname}";
    mainProgram = "mount-polaris";
  };
}

