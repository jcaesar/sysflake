{
  rustPlatform,
  fetchFromGitHub,
  lib,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "nvml-prometheus-exporter";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "jcaesar";
    repo = "nvml-prometheus-exporter";
    rev = "a1d458397872303e956702ebc4b10475c590201e";
    hash = "sha256-kPe2Owr5exktdfkk9GYL5qLjLWK5ubwPQ0XeKjEU40U=";
  };

  cargoSha256 = "sha256-lWe18iDoeTv3C98reHohUbomOTPFQlp0K9VakT6lY18=";

  meta = with lib; {
    description = "nvml / nvidia graphics card prometheus metrics exporter";
    license = licenses.mit;
    platforms = platforms.linux;
    homepage = "https://github.com/jcaesar/${pname}";
    mainProgram = "${pname}";
  };
}

