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
          })
          main
          ./variants.nix
        ];
      };
    work = import ./work.nix;
  in {
    nixosConfigurations =
      {
        korsika = sys ./korsika/configuration.nix;
        capri = sys ./capri/configuration.nix;
        mictop = sys ./mictop.nix;
        lasta = sys ./lasta.nix;
        pride = sys ./pride.nix;
        shamo0Install = sys ({lib, ...}: {
          imports = [
            (import ./shamo/configuration.nix 0)
            ({config, ...}: {
              config.boot.initrd.luks.devices = lib.mkForce {};
              config.fileSystems = {};
            })
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix"
          ];
        });
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
