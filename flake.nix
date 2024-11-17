{
  outputs = {
    nixpkgs,
    self,
    ...
  } @ flakes: let
    inherit (nixpkgs.lib) genAttrs attrNames attrValues mapAttrs filter concatMapAttrs flip;
    pkgsForSystem = system: import nixpkgs {inherit system;};
    genSystems = genAttrs ["x86_64-linux" "aarch64-linux"];
    eachSystem = f: genSystems (system: f (pkgsForSystem system));
    sys = system: main:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit flakes system;};
        modules = builtins.attrValues self.nixosModules ++ [main];
      };
    sysI = sys "x86_64-linux";
    sysA = sys "aarch64-linux";
    work = import ./work.nix;
  in {
    inherit flakes;
    nixosConfigurations =
      {
        korsika = sysI ./sys/korsika/configuration.nix;
        capri = sysI ./sys/capri/configuration.nix;
        # gemini5 = sysI ./sys/gemini5.nix;
        gozo = sysI ./sys/gozo.nix;
        mictop = sysI ./sys/mictop.nix;
        pride = sysI ./sys/pride.nix;
        doggieworld = sysI ./sys/doggieworld/configuration.nix;
        spitz = sysI ./sys/spitz/configuration.nix;
        drosophila = sysI ./sys/drosophila.nix;
        pitivi = sysA ./sys/pitivi.nix;
        gegensprech = sysA ./sys/gegensprech.nix;
        basenji = sysI ./sys/basenji.nix;
      }
      // work.shamo.eachNixed (index: {
        name = "shamo${toString index}";
        value = sysI ((import ./sys/shamo.nix) index);
      });
    nixosModules = {
      njx = import ./mod;
      home-manager = flakes.home-manager.nixosModules.home-manager;
      disko = flakes.disko.nixosModules.disko;
    };
    overlays.default = final: prev: import ./pkgs final prev;
    formatter = eachSystem (pkgs: pkgs.alejandra);
    checks = genSystems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = attrValues self.overlays;
        };
        myPkgs = genAttrs (attrNames (self.overlays.default null null)) (p: pkgs.${p});
        pkgTests = flip concatMapAttrs myPkgs (pkgName: pkg:
          flip concatMapAttrs (pkg.tests or {}) (testName: test: let
            nixosLib = import "${nixpkgs}/nixos/lib" {};
          in {
            "${pkgName}_${testName}" = nixosLib.runTest {
              hostPkgs = pkgs;
              imports = [test];
            };
          }));
        sysTests = mapAttrs (_: sys: sys.config.system.build.toplevel) self.nixosConfigurations;
        aggSys = let
          all = attrNames self.nixosConfigurations;
          linkFor = sys: "ln -s ${self.nixosConfigurations.${sys}.config.system.build.toplevel} $out/${sys}";
          links = filt: builtins.concatStringsSep "\n" (map linkFor (filter (name: filt name) all));
          toplevels = filt:
            pkgs.runCommandLocal "toplevels" {} ''
              mkdir $out
              ${links filt}
            '';
        in {
          workSys = toplevels (name: self.nixosConfigurations.${name}.config.njx.work);
          privSys = toplevels (name: !self.nixosConfigurations.${name}.config.njx.work);
          allSys = toplevels (_: true);
        };
      in
        myPkgs
        // pkgTests
        // sysTests
        // aggSys
    );
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
}
