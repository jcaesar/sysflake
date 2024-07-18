#!/usr/bin/env nu

def tag [hostname: string] {
  from json | each {|l|
    if $l.configurationRevision != "" and $l.configurationRevision !~ "-dirty" {
      let tag = $"($hostname)-($l.generation)"
      let rev = (do { git rev-parse $"refs/tags/($tag)" } | complete | get exit_code)
      if $rev == 128 {
        let desc = ($l | select date generation kernelVersion nixosVersion | to yaml)
        git tag -a -m $desc $tag $l.configurationRevision
        return $"($tag) created"
      }
    }
  }
}

def main [host?: string] {
  if ($host == work) {
    [shamo0 shamo2 shamo4 shamo6 shamo7 capri null gozo gemini5] | par-each { main $in }
  } else if ($host == home) {
    [pride null] | par-each { main $in }
  } else if ($host == null) {
    nixos-rebuild --no-build-nix list-generations --json | tag (hostname)
  } else {
    ssh -q $host nixos-rebuild --no-build-nix list-generations --json | tag (ssh -q $host hostname)
  }
}
