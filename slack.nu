#!/usr/bin/env nu

def fmttime [] {
  format date "%Y-%m-%d %H:%M"
}

def main [] {
  git tag 
  | lines | parse "{machine}-{rev}"  | group-by machine 
  | items {|machine, revs| 
    let tag = $"($machine)-($revs.rev | math max)"
    let rev = (git rev-list -n1 $tag | cut -c-7)
    let lock = (git show $"($tag):flake.lock" | from json)
    let dates = ($lock 
      | get nodes 
      | items {|k, v|
        if "locked" in $v { 
          {input: $k, date: ($v.locked.lastModified * 10 ** 9 | into datetime | fmttime)} 
        } 
      }
      | where { $in != null }
    ) 
    {
      machine: $machine,
      rev: $rev,
      tag: (git tag --format '%(*authordate)' -n1 $tag | fmttime),
    } | merge ($dates | transpose -rid)
  }
}