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
    repo = pname;
    rev = "e4342f982b99e019269b25874d078e0643b4438d";
    hash = "sha256-VJ3H1MxvNv9wG/p7W51QtnMqJYhooyH1FlIw8f9tSW0=";
  };
  cargoSha256 = "sha256-9jYltiEiJgc9VsZtpTS7/t/3lUswbARfP7O9avJDf9o=";

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
