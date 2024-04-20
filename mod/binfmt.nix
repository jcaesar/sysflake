{
  lib,
  pkgs,
  ...
}: {
  boot.binfmt.emulatedSystems = ["armv7l-linux" "wasm32-wasi" "wasm64-wasi" "x86_64-windows"];
  environment.etc."binfmt.d/nix-hack-qemu-user-statc.conf".text = let
    pr = pkgs.fetchFromGitHub {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "pull/300070/head"; #"d01bb6a1f7b820437406b4b341f77537c04bdc50";
      hash = "sha256-7uBcm17HVjPW5JBmEnyg+yVb1qDkiXHKfeLjR7wfyek=";
    };
    patched = import pr {system = "x86_64-linux";};
    # Workaround for https://github.com/NixOS/nixpkgs/issues/295608
    qus = patched.qemu-user-static.override {
      pkgsStatic =
        patched.pkgsStatic
        // {
          qemu = patched.pkgsStatic.qemu.override {
            texinfo = patched.pkgsStatic.texinfo.override {
              perl = pkgs.perl;
            };
            hostCpuTargets = ["aarch64-linux-user"];
          };
        };
    };
  in
    lib.concatStringsSep ":" [
      ""
      "aarch64-linux"
      "M"
      ""
      "\\x7fELF\\x02\\x01\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x02\\x00\\xb7\\x00"
      "\\xff\\xff\\xff\\xff\\xff\\xff\\xff\\x00\\xff\\xff\\xff\\xff\\xff\\xff\\x00\\xff\\xfe\\xff\\xff\\xff"
      "${qus}/bin/qemu-aarch64"
      "FOCP"
    ];
}
