{
  flakes,
  modulesPath,
  ...
}: let
  mkModOption = name: {
    lib,
    config,
    pkgs,
    ...
  } @ args: {
    options.njx.${name} = lib.mkEnableOption "/mod/${name}.nix";
    config = lib.mkIf config.njx.${name} (import ./${name}.nix args);
  };
in {
  options.njx = {
  };
  imports = [
    flakes.home-manager.nixosModules.home-manager
    flakes.disko.nixosModules.disko
    "${modulesPath}/installer/scan/not-detected.nix"
    ./variants.nix
    (mkModOption "base")
    (mkModOption "binfmt")
    (mkModOption "bluetooth")
    (mkModOption "common")
    (mkModOption "dlna")
    (mkModOption "firefox/default")
    (mkModOption "graphical")
    (mkModOption "prometheus-nvml-exporter")
    (mkModOption "squid")
  ];
}