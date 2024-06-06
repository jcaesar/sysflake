{
  lib,
  pkgs,
  ...
}: let
  arches = ["aarch64-linux" "armv7l-linux" "riscv64-linux"];
  qus = pkgs.pkgsStatic.qemu-user.override {inherit arches;};
in {
  boot.binfmt.emulatedSystems = arches ++ ["wasm32-wasi" "wasm64-wasi" "x86_64-windows"];
  boot.binfmt.registrations = let
    attrs = sys: {
      interpreter = "${qus.passthru.binaryFor sys}";
      wrapInterpreterInShell = false;
      preserveArgvZero = true;
      matchCredentials = true;
      fixBinary = true;
    };
  in
    lib.genAttrs arches attrs;
}
