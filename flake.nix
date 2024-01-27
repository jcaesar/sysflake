{
  outputs = {
    self,
    nixpkgs,
    home-manager,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    sys = main:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          enableHM = {
            imports = [
              home-manager.nixosModules.home-manager
              ({ ... }: {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
              })
            ];
          };
        };
        modules =
          [
            ({...}: {
              nix.settings.experimental-features = ["nix-command" "flakes"];
              nix.registry.nixpkgs.flake = nixpkgs;
              nix.nixPath = ["nixpkgs=${nixpkgs}"];
              system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
            })
            main
          ];
      };
  in {
    nixosConfigurations."korsika" = sys ./korsika/configuration.nix;
    nixosConfigurations."mictop" = sys ./mictop.nix;
    nixosConfigurations."pride" = sys ./pride.nix;
    formatter.${system} = pkgs.alejandra;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
}
