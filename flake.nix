{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11-small";
  outputs = { self, nixpkgs }:
    let
      common = import ./common.nix;
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
      shamos = f: builtins.listToAttrs (map f common.shamo.nixed);
    in
    {
      nixosConfigurations =
        { capri = fromCfg ./capri/configuration.nix; } # VM on gemini
        // shamos (index: {
          name = "shamo${toString index}";
          value = fromCfg ((import ./shamo/configuration.nix) index);
        });
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    };
}
