{
  outputs =
    { self, nixpkgs }:
    {
      packages.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          inherit (pkgs) lib;
          inherit (lib) getExe makeOverridable;
        in
        rec {
          src = pkgs.requireFile {
            hash = "sha256-5Qk+7NLTyIztKXzcjZnd1t7RW5hrUGiUPVkkFdHWWW4=";
            name = "*****secret*****_deb.tar.gz";
            url = "Somewhere on sharepoint";
          };
          unpacked =
            pkgs.runCommand "cxdr"
              {
                nativeBuildInputs = [ pkgs.binutils ];
              }
              ''
                tar xvf ${src}
                ar x *.deb
                tar xvf data.tar
                mkdir $out
                mv opt $out
              '';
          certs = pkgs.cacert.override {
            extraCertificateFiles = [
              (pkgs.fetchurl {
                url = "https://certs.godaddy.com/repository/gdroot-g2.crt";
                hash = "sha256-UAMpq6wQCpU6c5a1Sza+V9MzAi8XQBvJSCSOoXnPF4Q=";
              })
              (pkgs.fetchurl {
                url = "https://certs.godaddy.com/repository/gd-class2-root.crt";
                hash = "sha256-R/FaUqmEqx+c2StsGEnARlwbPJxoN9VOXSwAT6Ababc=";
              })
            ];
          };
          fakeCerts = pkgs.runCommand "ca-certificates" {} ''
            mkdir -p $out/etc/ssl/certs
            cat ${certs}/etc/ssl/certs/ca-bundle.crt >$out/etc/ssl/certs/ca-certificates.crt
          '';
          fakeRelease = pkgs.writeTextDir "etc/os-release" ''
            ID=ubuntu
            VERSION_ID="24.04"
          '';
          fakeDebianPackages = pkgs.writeScriptBin "dpkg-query" ''
            #!/bin/bash
            set -euo pipefail
            if echo "$@" | grep -qE "openssl"; then
              if echo "$@" | grep -qE "Status"; then
                echo "install ok installed"
              elif echo "$@" | grep -qE "Version"; then
                echo ${pkgs.openssl.version}
              else
                echo prettyplease
              fi
            elif echo "$@" | grep -qE "ca-certificates"; then
              echo "install ok installed"
            else
              exit 1
            fi
          '';
          env = makeOverridable pkgs.buildFHSEnv {
            name = "install-env";
            targetPkgs =
              pkgs: [
                pkgs.coreutils
                pkgs.openssl
                pkgs.getopt
                pkgs.bash
                pkgs.iptables
                pkgs.systemd
                pkgs.procps

                pkgs.fakeroot
                pkgs.shadow
                # unpacked
                fakeRelease
                fakeDebianPackages
                fakeCerts
              ];
            extraBuildCommands = ''
              install -D ${pkgs.linux_6_1.configfile} $out/boot/config-${pkgs.linux_6_1.version}
            '';
          };
          default = pkgs.runCommand "goretags" {} ''
            # must create to-be-writable directories.
            mkdir -p out/var/log out/opt out/etc/systemd/system out/tmp work
            echo root:x:0:0:System administrator:/root:/run/current-system/sw/bin/bash >out/etc/passwd
            echo root:x:0: >out/etc/group
            echo root:!:1:::::: >out/etc/shadow
            cp -ar ${unpacked}/opt/*/deb-installer out/tmp/
            chmod -R u+w out/tmp/deb-installer
            ${getExe pkgs.bubblewrap} \
              --die-with-parent \
              --unshare-user --uid 0 --gid 0 \
              --overlay-src ${env.fhsenv} --overlay ./out ./work / \
              --dev-bind /dev /dev --proc /proc \
              --ro-bind /nix /nix \
              -- \
              /usr/bin/fakeroot /usr/bin/bash -ec "
                source /etc/profile
                function umask {
                  echo Ignoring call: umask \$@
                }
                cd /tmp/deb-installer
                set -- --vm-template
                BASH_ARGV0=./setup.sh
                source ./setup.sh
              "
            rmdir out/nix out/proc out/dev
            rm -rf out/tmp
            mv out $out
          '';
        };
    };
}
