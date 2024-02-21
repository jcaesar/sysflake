#!/usr/bin/env bash

# Preceed with: nix flake update

set -euo pipefail

if ! which nixos-rebuild &>/dev/null; then
	nix shell nixpkgs\#nixos-rebuild -c "$0" "$@"
fi

cd "$(dirname "$0")"

export NIX_SSHOPTS="-q -oCompression=yes"

for h in {0,2,6,7}; do
	echo -en "\nshamo$h\n======\n"
	nixos-rebuild switch --target-host "shamo$h" --build-host shamo2 --flake ".#shamo$h" || echo 1>&2 "shamo$h failed"
done
