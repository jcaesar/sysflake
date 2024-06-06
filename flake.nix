{
  outputs = {
    self,
    nixpkgs,
    home-manager,
    disko,
  }: let
    pkgsForSystem = system: import nixpkgs {inherit system;};
    eachSystem = f: nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"] (system: f (pkgsForSystem system));
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
            nix.registry.n.flake = nixpkgs;
            nix.registry.sf.flake = self;
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
          # This doesn't add any scripts to system packages.
          # But one can get the script with
          # nix build $(realpath /etc/sysflake/self)#nixosConfigurations.$(hostname).config.system.build.diskoScript
          # For some reason, installing after that only worked with
          # nixos-install --system $(nix build --no-link --print-out-paths $(realpath /etc/sysflake/self)#nixosConfigurations.$(hostname).config.system.build.toplevel)
          #
          # It's possible to do better, but bllr
          # https://github.com/nix-community/disko/blob/cdefe26742f442351e73ce0f7caa3f559be32dc6/docs/disko-install.md#example-for-a-nixos-installer
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
        pitivi = sysA ./sys/pitivi.nix;
      }
      // work.shamo.eachNixed (index: {
        name = "shamo${toString index}";
        value = sysI ((import ./sys/shamo.nix) index);
      });
    packages = eachSystem (pkgs: import ./pkgs pkgs pkgs);
    formatter = eachSystem (pkgs: pkgs.alejandra);
    tests = eachSystem (pkgs: let
      nixosLib = import "${nixpkgs}/nixos/lib" {};
      myPkgs = import ./pkgs pkgs pkgs;
      hostPkgs = import nixpkgs {
        inherit (pkgs) system;
        overlays = [(import ./pkgs)];
      };
    in
      builtins.mapAttrs (pkgName: pkg:
        builtins.mapAttrs (testName: test:
          nixosLib.runTest {
            inherit hostPkgs;
            imports = [test];
          }) ((pkg.passthru or {}).tests or {}))
      myPkgs);
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05-small";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
}
