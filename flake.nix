{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    nixosConfigurations."korsika" = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        (import ./configuration.nix)
        ({...}: {nix.registry.nixpkgs.flake = nixpkgs;})
      ];
    };

    formatter.${system} = pkgs.alejandra;
  };
}
