pkgs: {
  cyrly = pkgs.callPackage ./cyrly.nix {};
  polaris-fuse = pkgs.callPackage ./polaris-fuse.nix {};
  prometheus-nvml-exporter = pkgs.callPackage ./prometheus-nvml-exporter.nix {};
  pyanidb = pkgs.python3Packages.callPackage ./pyanidb.nix {};
  njx = import ./njx.nix pkgs;
  rowserext = import ./rowserext.nix pkgs;
}
