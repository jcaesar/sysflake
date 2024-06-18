final: prev: {
  cyrly = final.callPackage ./cyrly.nix {};
  polaris-fuse = final.callPackage ./polaris-fuse.nix {};
  prometheus-nvml-exporter = final.callPackage ./prometheus-nvml-exporter.nix {};
  pyanidb = final.python3.pkgs.callPackage ./pyanidb.nix {};
  njx = final.callPackage ./njx.nix {};
  rowserext = final.callPackage ./rowserext.nix {};
  colmap = import ./colmap.nix prev;
  archivebox = import ./archivebox.nix prev;
  qemu-user-static = final.pkgsStatic.callPackage ./qemu-user.nix {};
}
