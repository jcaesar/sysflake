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
      return $"($tag) existed"
    }
  }
}

def main [host?: string] {
  if ($host == null) {
    nixos-rebuild --no-build-nix list-generations --json | tag (hostname)
  } else {
    ssh $host nixos-rebuild --no-build-nix list-generations --json | tag (ssh $host hostname)
  }
}
