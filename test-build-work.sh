#!/usr/bin/env bash

set -euo pipefail
export NIX_SSHOPTS="-q -oCompression=yes -oControlMaster=auto -oControlPath=/tmp/ssh-check-nix-build-%C -oControlPersist=60"
target=shamo2
set -x

drv="$(nix eval -vL --raw .#tests.x86_64-linux.workSys.drvPath)"
nix copy -vL -s --derivation --to ssh://$target "$drv^*"
ssh -tt $NIX_SSHOPTS $target nix build -vL -o /tmp/check-nix-hostbuilds --keep-going "$drv^*" --builders '"shamo0;shamo4;shamo6;shamo7"'
