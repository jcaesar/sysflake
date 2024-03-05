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
            environment.etc."sysflake/self".source = self;
            environment.etc."sysflake/nixpkgs".source = nixpkgs;
            environment.etc."sysflake/home-manager".source = home-manager;
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
        doggieworld = sys ./doggieworld/configuration.nix;
        installerBCacheFS = sys ./installer.nix;
        tmpPicardLive = sys ({lib, ...}: {
          imports = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix"
          ];
          environment.defaultPackages = with pkgs; [
            picard
            picard-tools
          ];
          virtualisation.vmware.guest.enable = lib.mkForce false;
          virtualisation.hypervGuest.enable = lib.mkForce false;
          services.xe-guest-utilities.enable = lib.mkForce false;
          virtualisation.virtualbox.guest.enable = lib.mkForce false;
          boot.plymouth.enable = lib.mkForce false;
          fileSystems."/host" = {
            device = "host";
            fsType = "virtiofs";
            options = ["noauto" "x-systemd.automount" "user_id=1000" "group_id=100" "allow_other" "_netdev" "noexec" "nosuid" "nodev" "noatime"];
          };
        });
      }
      // work.shamo.eachNixed (index: {
        name = "shamo${toString index}";
        value = sys ((import ./shamo.nix) index);
      });

    formatter.${system} = pkgs.alejandra;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
}
