{
  outputs = {
    self,
    nixpkgs,
    nixpkgs-certmgrfix,
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
            system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
          })
          ({...}: {
            nixpkgs.overlays = [
              (final: prev: {certmgr-selfsigned = (import nixpkgs-certmgrfix {inherit system;}).certmgr-selfsigned;})
            ];
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
        installerBCacheFS = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix"
            ({
              lib,
              pkgs,
              ...
            }: {
              boot.supportedFilesystems = ["bcachefs"];
              boot.kernelPackages = lib.mkOverride 0 pkgs.linuxPackages_latest;
            })
          ];
        };
      }
      // work.shamo.eachNixed (index: {
        name = "shamo${toString index}";
        value = sys ((import ./shamo/configuration.nix) index);
      });

    formatter.${system} = pkgs.alejandra;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-certmgrfix.url = "github:nixos/nixpkgs/2e682b7d19f541e605c66f811d40da6c104858f8";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
}
