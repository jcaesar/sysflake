#!/usr/bin/env nu

nixos-rebuild list-generations --json
| from json | each {|l|
  if $l.configurationRevision != "" {
    let tag = $"(hostname)-($l.generation)"
    let rev = (do { git rev-parse $"refs/tags/($tag)" } | complete | get exit_code)
    if $rev == 128 {
      let desc = ($l | select date generation kernelVersion nixosVersion | to yaml)
      git tag -a -m $desc $tag $l.configurationRevision
      return $"($tag) created"
    }
    return $"($tag) existed"
  }
}
    
