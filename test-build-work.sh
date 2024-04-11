#!/usr/bin/env bash

set -euo pipefail

if ! which nixos-rebuild &>/dev/null; then
	nix shell nixpkgs\#nixos-rebuild -c "$0" "$@"
fi

cd "$(dirname "$0")"

export NIX_SSHOPTS="-q -oCompression=yes -oControlMaster=auto -oControlPath=/tmp/ssh-check-nix-build-%C -oControlPersist=60"
target=shamo2
exit=true
for h in korsika capri shamo{0,2,4,6,7}; do
	(
		echo -en "\n$h\n$(echo $h | sed 's/./=/g')\n"
		set -x
		drv="$(nix eval -L --raw .#nixosConfigurations.$h.config.system.build.toplevel.drvPath --verbose)"
		nix copy -vL -s --derivation --to ssh://$target "$drv^*"
		ssh $NIX_SSHOPTS $target nix build -vL -o /tmp/check-nix-hostbuild-$h "$drv^*"
	) && status=$? || status=$?
	if test $status -ne 0; then
		echo 1>&2 "$h failed"
		exit=false
	fi
done

$exit
