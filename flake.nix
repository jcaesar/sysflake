{
  outputs = {
    self,
    nixpkgs,
    home-manager,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    sys = modules:
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules =
          [
            ({...}: {
              nix.registry.nixpkgs.flake = nixpkgs;
              nix.nixPath = ["nixpkgs=${nixpkgs}"];
              system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
            })
          ]
          ++ modules;
      };
    hmmods = [
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.julius = import ./home.nix;
      }
    ];
  in {
    nixosConfigurations."korsika" = sys ([(import ./korsika/configuration.nix)] ++ hmmods);
    nixosConfigurations."mictop" = sys ([(import ./mictop.nix)] ++ hmmods);
    formatter.${system} = pkgs.alejandra;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
}
