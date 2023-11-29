#!/usr/bin/env bash

# Preceed with: nix flake update

set -euo pipefail

if ! which nixos-rebuild &>/dev/null; then
	nix shell nixpkgs\#nixos-rebuild -c "$0" "$@"
fi

cd "$(dirname "$0")"

export NIX_SSHOPTS=-q

echo -en "\ncapri\n=====\n"
nixos-rebuild switch --target-host capri --build-host capri --use-remote-sudo --flake .\#capri

for h in {2,6,7}; do
	echo -en "\nshamo$h\n======\n"
	nixos-rebuild switch --target-host "shamo$h" --build-host shamo2 --flake ".#shamo$h"
done
