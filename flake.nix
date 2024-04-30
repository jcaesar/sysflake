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
            nix.registry.nixpkgs.flake = nixpkgs;
            nix.registry.n.flake = nixpkgs;
            nix.nixPath = ["nixpkgs=${nixpkgs}"];
            system.configurationRevision =
              self.rev or self.dirtyRev or "nogit";
            system.nixos.version = let
              r = self.shortRev or self.dirtyShortRev or "nogit";
            in "j_${r}_${self.lastModifiedDate}";
            environment.etc."sysflake/self".source = self;
            environment.etc."sysflake/nixpkgs".source = nixpkgs;
            environment.etc."sysflake/home-manager".source = home-manager;
          })
          main
          ./mod/variants.nix
        ];
      };
    work = import ./work.nix;
  in {
    nixosConfigurations =
      {
        korsika = sys ./sys/korsika/configuration.nix;
        capri = sys ./sys/capri/configuration.nix;
        mictop = sys ./sys/mictop.nix;
        lasta = sys ./sys/lasta/configuration.nix;
        pride = sys ./sys/pride.nix;
        doggieworld = sys ./sys/doggieworld/configuration.nix;
        installerBCacheFS = sys ./sys/installer.nix;
      }
      // work.shamo.eachNixed (index: {
        name = "shamo${toString index}";
        value = sys ((import ./sys/shamo.nix) index);
      });
    packages.${system} = import ./pkgs pkgs;
    formatter.${system} = pkgs.alejandra;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
}
