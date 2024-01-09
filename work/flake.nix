{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11-small";
  inputs.nixpkgs-certmgrfix.url = "github:nixos/nixpkgs/nixos-23.05-small";
  outputs = {
    self,
    nixpkgs,
    nixpkgs-certmgrfix,
  }: let
    common = import ./common.nix;
    system = "x86_64-linux";
    fromCfg = cfg:
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          cfg
          ({...}: {
            nix.registry.nixpkgs.flake = nixpkgs;
            system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
            nixpkgs.overlays = [
              (final: prev: {certmgr-selfsigned = (import nixpkgs-certmgrfix {inherit system;}).certmgr-selfsigned;})
            ];
          })
        ];
      };
    shamos = f: builtins.listToAttrs (map f common.shamo.nixed);
  in {
    nixosConfigurations =
      {capri = fromCfg ./capri/configuration.nix;} # VM on gemini
      // shamos (index: {
        name = "shamo${toString index}";
        value = fromCfg ((import ./shamo/configuration.nix) index);
      });
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
  };
}
