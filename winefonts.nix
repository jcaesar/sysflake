{
  wine,
  stdenvNoCC,
  ...
}:
stdenvNoCC.mkDerivation {
  name = "winefonts";
  phases = ["installPhase" "fixupPhase"];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    cp -at $out/share/fonts/truetype/ ${wine}/share/wine/fonts/*.ttf

    runHook postInstall
  '';

  meta = {
    description = "Steal fonts from Wine";
  };
}
