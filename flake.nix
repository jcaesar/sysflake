{
  outputs = {
    self,
    nixpkgs,
    home-manager,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    sysSingle = variantModule: main:
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
          variantModule
          main
        ];
      };
    sys = main: sysSingle ({...}: {}) main //
      {
        installerMinimal = sysSingle "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix" main;
        installerGraphical = sysSingle "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix" main;
        # nix build --show-trace -vL .#nixosConfigurations.${host}.netbootMinimal.config.system.build.kexecTree
        netbootMinimal = sysSingle "${nixpkgs}/nixos/modules/installer/netboot/netboot-minimal.nix" main;
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
