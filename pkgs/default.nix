pkgs: {
  cyrly = pkgs.callPackage ./cyrly.nix {};
  prometheus-nvml-exporter = pkgs.callPackage ./prometheus-nvml-exporter.nix {};
  gegensprech = pkgs.callPackage ./gegensprech.nix {};
  pyanidb = pkgs.python3.pkgs.callPackage ./pyanidb.nix {};
  junix = pkgs.python3.pkgs.callPackage ./junix.nix {};
  njx = pkgs.callPackage ./njx.nix {};
  rowserext = pkgs.callPackage ./rowserext.nix {};
  colmap = import ./colmap.nix pkgs;
}
