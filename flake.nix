{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
  outputs = { self, nixpkgs }: let
    fromCfg = cfg: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        cfg
        ({ ... }: {
          nix.registry.nixpkgs.flake = nixpkgs;
          system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
        })
      ];
    };
    mkShamo = index: fromCfg ((import ./shamo/configuration.nix) index);
  in {
    nixosConfigurations = 
      { capri = fromCfg ./capri/configuration.nix; } # VM on gemini
      //  builtins.listToAttrs (map (index: { 
        name = "shamo${toString index}";
        value = fromCfg ((import ./shamo/configuration.nix) index); 
      }) [2 7 8]);
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
  };
}
