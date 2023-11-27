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
  in {
    nixosConfigurations.capri = fromCfg ./configuration.nix; # VM on gemini
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
  };
}
