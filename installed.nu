#!/usr/bin/env nu

let host = (hostname)
let live = (nix-store --gc --print-live | lines | where { $in =~ \.drv$ } | uniq | group-by)
glob /nix/store/*.drv | each { $"($in)^*" } | group 500 | par-each { 
  nix derivation show ...$in 
  | from json
  | items {|k, v| $v | insert drv $k }
  | where { $in.outputs | values | any { $in.path | path exists  }}
  | where { "pname" in $in.env }
  | each { {
    name: $in.env.pname,
    version: $in.env.version?,
    host: $host,
    live: ($in.drv in $live),
  } }
}
| flatten 
| group-by { $"($in.name) ($in.version)" } | values
| each { $in | sort-by -r live | get 0 }
| sort-by name version
| to json
