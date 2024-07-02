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
    "${modulesPath}/installer/scan/not-detected.nix"
    ./variants.nix
    ./ssh-unlock.nix
    ./wg-doggieworld.nix
    (mkModOption "base")
    (mkModOption "binfmt")
    (mkModOption "bluetooth")
    (mkModOption "common")
    (mkModOption "dlna")
    (mkModOption "firefox/default")
    (mkModOption "graphical")
    (mkModOption "prometheus-nvml-exporter")
    (mkModOption "squid")
    (mkModOption "work")
  ];
}
