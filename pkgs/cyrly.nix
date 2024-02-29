{
  rustPlatform,
  fetchFromGitHub,
  lib,
}:
rustPlatform.buildRustPackage rec {
  pname = "cyrly-conv";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "jcaesar";
    repo = "cyrly";
    rev = "f67cee648cd1d8a448dd4aca584f1847f53e5919";
    hash = "sha256-Yr/wLggIcYHhzfLxtdHd4ld4zuQwc/adM9UgpDn4dOY=";
  };
  cargoLock.lockFile = "${src}/Cargo.lock";

  cargoBuildFlags = ["--package=${pname}"];

  meta = with lib; {
    description = "A serde-based YAML serializer for Rust with an unusual output style.";
    license = licenses.mit;
    platforms = platforms.linux;
    homepage = "https://github.com/jcaesar/cyrly";
    mainProgram = "cyrly";
  };
}
