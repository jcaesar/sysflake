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
              ({...}: {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
              })
            ];
          };
        };
        modules = [
          ({...}: {
            nix.settings.experimental-features = ["nix-command" "flakes"];
            nix.registry.nixpkgs.flake = nixpkgs;
            nix.nixPath = ["nixpkgs=${nixpkgs}"];
            system.configurationRevision =
              if self ? rev
              then self.rev
              else self.dirtyRev;
            system.nixos.version = "j_${
              if self ? shortRev
              then self.shortRev
              else self.dirtyShortRev
            }_${self.lastModifiedDate}";
          })
          main
        ];
      };
    work = import ./work.nix;
  in {
    nixosConfigurations =
      {
        korsika = sys ./korsika/configuration.nix;
        capri = sys ./capri/configuration.nix;
        mictop = sys ./mictop.nix;
        pride = sys ./pride.nix;
        installerBCacheFS = sys ./installer.nix;
      }
      // work.shamo.eachNixed (index: {
        name = "shamo${toString index}";
        value = sys ((import ./shamo/configuration.nix) index);
      });

    formatter.${system} = pkgs.alejandra;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
}
