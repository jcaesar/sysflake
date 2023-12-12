{
  outputs = {
    self,
    nixpkgs,
    home-manager,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    nixosConfigurations."korsika" = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        (import ./configuration.nix)
        ({...}: {
          nix.registry.nixpkgs.flake = nixpkgs;
          nix.nixPath = ["nixpkgs=${nixpkgs}"];
        })
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.julius = import ./home.nix;
        }
      ];
    };

    formatter.${system} = pkgs.alejandra;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
}
