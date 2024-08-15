{
  lib,
  pkgs,
  ...
}: let
  systems = ["aarch64-linux" "armv7l-linux" "riscv64-linux"];
  arches = lib.genAttrs systems (system: (lib.systems.elaborate {inherit system;}).qemuArch);
  hostCpuTargets = map (system: "${arches.${system}}-linux-user") systems;
  qus = pkgs.pkgsStatic.qemu-user.override {inherit hostCpuTargets;};
  qusAttrs = system: {
    interpreter = "${lib.getExe' qus "qemu-${arches.${system}}"}";
    wrapInterpreterInShell = false;
    preserveArgvZero = true;
    matchCredentials = true;
    fixBinary = true;
  };
in {
  boot.binfmt.emulatedSystems = systems ++ ["wasm32-wasi" "wasm64-wasi" "x86_64-windows"];
  boot.binfmt.registrations = lib.genAttrs systems qusAttrs;
}
