{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }:
    {
      nixosConfigurations.pride = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ (import ./configuration.nix)
(        { ... }: {   nix.settings.experimental-features = [ "nix-command" "flakes" ]; })
        ];
      };
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    };
}
