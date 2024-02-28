#!/usr/bin/env bash

nix-store --gc --print-live \
| sed -n 's/.drv$/&^*/p' \
| xargs -r nix derivation show \
| jq --arg host "$(hostname)" -rc 'to_entries[].value.env | select(.pname) | [.pname, .version, "nixpkgs", $host] | @csv' \
| sort | uniq
