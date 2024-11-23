{lib, pkgs, config, ...}: {
options.njx.extraInitrdClosures = lib.mkOption {
  default = [];
  };
  config.boot.initrd.systemd.storePaths = let
    inherit (lib) splitString removeSuffix;
    inherit (pkgs) writeClosure writeText;
    inherit (builtins) readFile toJSON;
    json = toJSON config.njx.extraInitrdClosures;
    jsonFile = writeText "service-configs.json" json;
    closureFile = writeClosure jsonFile;
    closure = removeSuffix "\n" (readFile closureFile);
    paths = splitString "\n" closure;
  in
    paths;
}
