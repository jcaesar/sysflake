{
  outputs = {
    self,
    nixpkgs,
    home-manager,
    disko,
  }: let
    eachSystem = f: nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"] (system: f (import nixpkgs {inherit system;}));
    sys = system: main:
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
          disko.nixosModules.disko
          main
          ./mod/variants.nix
        ];
      };
    sysI = sys "x86_64-linux";
    sysA = sys "aarch64-linux";
    work = import ./work.nix;
  in {
    nixosConfigurations =
      {
        korsika = sysI ./sys/korsika/configuration.nix;
        capri = sysI ./sys/capri/configuration.nix;
        gozo = sysI ./sys/gozo.nix;
        mictop = sysI ./sys/mictop.nix;
        lasta = sysI ./sys/lasta/configuration.nix;
        pride = sysI ./sys/pride.nix;
        doggieworld = sysI ./sys/doggieworld/configuration.nix;
        installerBCacheFS = sysI ./sys/installer.nix;
        pitivi = sysA ./sys/pitivi.nix;
      }
      // work.shamo.eachNixed (index: {
        name = "shamo${toString index}";
        value = sysI ((import ./sys/shamo.nix) index);
      });
    packages = eachSystem (pkgs: import ./pkgs pkgs pkgs);
    formatter = eachSystem (pkgs: pkgs.alejandra);
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
}
