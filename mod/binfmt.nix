{
  lib,
  pkgs,
  ...
}: {
  boot.binfmt.emulatedSystems = ["aarch64-linux" "armv7l-linux" "riscv64-linux" "wasm32-wasi" "wasm64-wasi" "x86_64-windows"];
  boot.binfmt.registrations = let
    pr = pkgs.fetchFromGitHub {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "pull/314998/head"; # "d57f30155eb628f27f12d24c3e1fd6a30ee7fee7";
      hash = "sha256-rzcKVxTJqbkfUufo6Ogaoh50O9AtmTY/1jjRDNXZYk4=";
    };
    patched = import pr {inherit (pkgs) system;};
    qus = patched.pkgsStatic.qemu-user;
    attrs = sys: {
      interpreter = "${qus}/bin/qemu-${(lib.systems.elaborate sys).qemuArch}";
      wrapInterpreterInShell = false;
      preserveArgvZero = true;
      matchCredentials = true;
      fixBinary = true;
    };
  in
    lib.genAttrs ["aarch64-linux" "armv7l-linux" "riscv64-linux"] attrs;
}
