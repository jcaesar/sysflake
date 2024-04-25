{
  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    pkgsStable = import nixpkgs-stable {inherit system;};
    sys = main:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit pkgsStable;
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
            nix.registry.n.flake = nixpkgs;
            nix.nixPath = ["nixpkgs=${nixpkgs}"];
            system.configurationRevision =
              self.rev
              or self.dirtyRev or "nogit";
            system.nixos.version = "j_${
              self.shortRev
              or self.dirtyShortRev or "nogit"
            }_${self.lastModifiedDate}";
            system.systemBuilderCommands = "ln -s ${self} $out/sysflake";
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

    formatter.${system} = pkgs.alejandra;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11-small";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
}
