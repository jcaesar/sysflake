#!/usr/bin/env bash

# Preceed with: nix flake update

set -euo pipefail

#if ! which nixos-rebuild &>/dev/null; then
#	nix shell nixpkgs\#nixos-rebuild -c "$0" "$@"
#fi
#nixos-rebuild switch --target-host capri --build-host capri --use-remote-sudo --flake .#capri

cd "$(dirname "$0")"

for h in shan{2,6,7}; do
    echo
	echo "$h"
	echo $(sed 's/./=/g' <<<"$h")
	rsync -ae "ssh -q" . $h:./sysflake
	ssh -qtt $h sudo nixos-rebuild switch --flake ./sysflake
done
