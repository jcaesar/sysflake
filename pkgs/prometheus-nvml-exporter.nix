{
  rustPlatform,
  fetchFromGitHub,
  lib,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "prometheus-nvml-exporter";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "jcaesar";
    repo = "prometheus-nvml-exporter";
    rev = "1f3be5d394d83631228ee5ae15117f5667c7718d";
    hash = "sha256-HOIbxQqKAI+yVHQ8RVEUr9Yj8mi7AzgKArhSbJDtLMI=";
  };
  cargoSha256 = "sha256-Yej4hgG6huZvwl6ZWbLIhCxfmKUe4NUnxRh63Giteb8=";

  meta = with lib; {
    description = "nvml / nvidia graphics card prometheus metrics exporter";
    license = licenses.mit;
    platforms = platforms.linux;
    homepage = "https://github.com/jcaesar/${pname}";
    mainProgram = "${pname}";
  };
}
