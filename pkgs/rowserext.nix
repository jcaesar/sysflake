{
  fetchFromGitHub,
  lib,
  wasm-bindgen-cli,
  rustc,
  rustPlatform,
  stdenv,
  just,
  cargo,
}:
stdenv.mkDerivation rec {
  pname = "rowserext";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "jcaesar";
    repo = "rowserext";
    rev = "84c7cb2fa341099ce5950ba47625dbbbff1456cf";
    hash = "sha256-W5HakGNbAyNydPY+9XZvrdXOllRxYQ26CnwYI2RHkkk=";
  };
  cargoDeps = rustPlatform.importCargoLock {
    lockFile = "${src}/Cargo.lock";
  };

  nativeBuildInputs = let
    wasm-bindgen = wasm-bindgen-cli.override {
      version = "0.2.87";
      hash = "sha256-0u9bl+FkXEK2b54n7/l9JOCtKo+pb42GF9E1EnAUQa0=";
      cargoHash = "sha256-AsZBtE2qHJqQtuCt/wCAgOoxYMfvDh8IzBPAOkYSYko=";
    };
  in [
    just
    rustc.llvmPackages.lld
    cargo
    wasm-bindgen
    rustPlatform.cargoSetupHook
  ];

  postPatch = ''
    runHook cargoSetupHook
    substituteInPlace */justfile --replace-fail 'cargo build' 'cargo build --frozen'
  '';
  env.CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_LINKER = "lld";
  buildPhase = ''
    for ex in lionel join-on-time; do
      pushd $ex
      just release
      rm pkg/*.ts
      popd
    done
  '';
  checkPhase = '''';
  installPhase = ''
    mkdir -p $out/lionel $out/join-on-time
    cp -art $out/lionel lionel/{manifest.json,*.js,*.svg,*.html,pkg/}
    cp -art $out/join-on-time join-on-time/{manifest.json,*.js,*.svg,pkg/}
  '';

  meta = with lib; {
    description = "Rust browser extensions";
    license = licenses.mit;
    platforms = platforms.linux;
    homepage = "https://github.com/jcaesar/rowserext";
  };
}
