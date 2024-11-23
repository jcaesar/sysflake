#!/usr/bin/env nu

cd $env.FILE_PWD
let target = "shamo2"
let flakemeta = nix flake metadata --json | from json
let flakepath = $"path:($flakemeta.path)?($flakemeta.locked | reject ref type url | url build-query)"
let attrpath = $"($flakepath)#checks.x86_64-linux.workSys"
let sshopts = [-q -oCompression=yes -oControlMaster=auto -oControlPath=/tmp/ssh-check-nix-build-%C -oControlPersist=60]
$env.NIX_SSHOPTS = $sshopts | str join " "

nix copy --to ssh://($target) $flakemeta.path
ssh -tt ...$sshopts $target nom build -o /tmp/check-nix-hostbuilds --keep-going --builders "'shamo0;shamo4;shamo6;shamo7'" $"'($attrpath)'"

