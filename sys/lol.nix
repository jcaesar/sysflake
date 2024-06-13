{
  lib,
  pkgs,
  config,
  ...
}: let
  linux = let
    patched = builtins.getFlake "github:jcaesar/fork2pr-nixpkgs/84b9867048928648c80b1f438e61ce0bc5d9ba7d"; # branch pr-10
    ppkgs = import patched {inherit (pkgs) system;};
    ob = ppkgs.linux.override {
      kernelArch = "um";
      ignoreConfigErrors = true;
      perferBuiltin = true;
      autoModules = false;
    };
    oa = ob.overrideAttrs (old: {
      buildFlags = lib.remove "bzImage" old.buildFlags ++ ["linux"];
      installPhase = ''
        # there doesn't seem to be an install target for um
        install -Dm555 ./vmlinux $out/bin/vmlinux
        ln -s $out/bin/vmlinux $out/bin/linux
      '';
      meta = old.meta // {mainProgram = "vmlinux";};
    });
  in
    oa;
  # getting networking to work would require some interesting archeology.
  # This thing's got 17 patches on debian, including two CVEs…
  # bess might be easier.
  slirp = pkgs.stdenv.mkDerivation {
    pname = "slirp";
    version = "1.0.17";
    src = let arc = pkgs.fetchzip {
      url = "mirror://sourceforge/project/slirp/slirp/1.0.16/slirp-1.0.16.tar.gz";
      hash = "sha256-0ZQCHMYcMZmRYlfdjNvmu6ZfY21Ux/1yJhUE3vnrjVo=";
    }; in "${arc}/src";
    patches = [
      (
        pkgs.fetchpatch {
          url = "mirror://sourceforge/project/slirp/slirp/1.0.17%20patch/slirp_1_0_17_patch.tar.gz";
          hash = "sha256-LxJKrT1EOrciTpzLjntlsc1clOxBHK/N7nWXgEZbATM=";
        }
      )
    ];
    buildInputs = [pkgs.libxcrypt];
  };
in {
  # boot.kernelPackages = linux;

  fileSystems."/" = {
    device = "-";
    fsType = "tmpfs";
  };
  fileSystems."/nix/store" = {
    device = "-";
    fsType = "hostfs";
    options = ["/nix/store"];
  };
  boot.loader.initScript.enable = false; # unlike the documentation for this option says, not actually required.
  boot.loader.grub.enable = false;

  system.build.uml = pkgs.writeScriptBin "umlvm" ''
    set -x
    exec ${lib.getExe linux} \
      mem=2G \
      init=${config.system.build.toplevel}/init \
      initrd=${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile} \
      con0=null,fd:2 con1=fd:0,fd:1 \
      ${toString config.boot.kernelParams}
  '';

  networking.hostName = "lol"; # short for linux on linux. olo

  boot.initrd.availableKernelModules = ["autofs4"]; # systemd doesn't stop complaining about it being missing
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.services.rescue.environment.SYSTEMD_SULOGIN_FORCE = "1";
  services.getty.autologinUser = "root";

  # startup is slow enough, disable some unused stuff (esp. networking)
  networking.firewall.enable = false;
  services.nscd.enable = false;
  networking.useDHCP = false;
  system.nssModules = lib.mkForce [];
  systemd.oomd.enable = false;

  system.stateVersion = "24.05";
}
