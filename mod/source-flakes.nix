{
  config,
  lib,
  flakes,
  ...
}: {
  options.njx.source-flakes = lib.mkEnableOption "flake sources in /etc";
  config.environment.etc = let
    mkLnk = name: flake: {
      name = "sysflake/${name}";
      value.source = flake;
    };
  in
    lib.mkIf config.njx.source-flakes (lib.mapAttrs' mkLnk flakes);
}
