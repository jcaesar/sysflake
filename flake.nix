{
  outputs = {
    nixpkgs,
    self,
    ...
  } @ flakes: let
    pkgsForSystem = system: import nixpkgs {inherit system;};
    eachSystem = f: nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"] (system: f (pkgsForSystem system));
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
    nixosConfigurations =
      {
        korsika = sysI ./sys/korsika/configuration.nix;
        capri = sysI ./sys/capri/configuration.nix;
        gemini5 = sysI ./sys/gemini5.nix;
        gozo = sysI ./sys/gozo.nix;
        mictop = sysI ./sys/mictop.nix;
        lasta = sysI ./sys/lasta/configuration.nix;
        pride = sysI ./sys/pride.nix;
        doggieworld = sysI ./sys/doggieworld/configuration.nix;
        spitz = sysI ./sys/spitz/configuration.nix;
        drosophila = sysI ./sys/drosophila.nix;
        pitivi = sysA ./sys/pitivi.nix;
        gegensprech = sysA ./sys/gegensprech.nix;
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
    packages = eachSystem (pkgs: import ./pkgs pkgs);
    formatter = eachSystem (pkgs: pkgs.alejandra);
    checks = eachSystem (
      pkgs: let
        myPkgs = self.packages.${pkgs.system};
        pkgTests = let
          nixosLib = import "${nixpkgs}/nixos/lib" {};
          hostPkgs = import nixpkgs {
            inherit (pkgs) system;
            overlays = [(_: _: myPkgs)];
          };
        in
          pkgs.lib.concatMapAttrs (pkgName: pkg:
            pkgs.lib.mapAttrs' (testName: test: {
              name = "${pkgName}_${testName}";
              value = nixosLib.runTest {
                inherit hostPkgs;
                imports = [test];
              };
            }) (pkg.tests or {}))
          myPkgs;
        sysTests = builtins.mapAttrs (_: sys: sys.config.system.build.toplevel) self.nixosConfigurations;
        aggSys = let
          inherit (builtins) attrNames filter;
          all = attrNames self.nixosConfigurations;
          linkFor = sys: "ln -s ${self.nixosConfigurations.${sys}.config.system.build.toplevel} $out/${sys}";
          links = filt: builtins.concatStringsSep "\n" (map linkFor (filter (name: filt name) all));
          toplevels = filt:
            pkgs.runCommand "toplevels" {} ''
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
