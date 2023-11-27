#!/usr/bin/env bash

# Preceed with: nix flake update

set -euo pipefail

cd "$(dirname "$0")"

for h in drad shan{2,6,7}; do
    echo
	echo "$h"
	echo $(sed 's/./=/g' <<<"$h")
	rsync -ae "ssh -q" . $h:./sysflake
	ssh -qtt $h sudo nixos-rebuild switch --flake ./sysflake
done
