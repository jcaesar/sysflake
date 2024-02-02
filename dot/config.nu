let load_direnv = {
  if (which direnv | is-empty) { return }
  direnv export json | from json | default {} | load-env
}
let user = (whoami)
let hostname = (hostname)

let external_completer = {|spans|

  let fish_completer = {|spans|
    fish --command $'complete "--do-complete=($spans | str join " ")"'
    | $"value(char tab)description(char newline)" + $in
    | from tsv --flexible --no-infer
  }

  let carapace_completer = {|spans: list<string>|
    carapace $spans.0 nushell ...$spans
    | from json
    | if ($in | default [] | where value =~ '^-.*ERR$' | is-empty) { $in } else { null }
  }

  let expanded_alias = scope aliases
  | where name == $spans.0
  | get -i 0.expansion

  let spans = if $expanded_alias != null {
    $spans
    | skip 1
    | prepend ($expanded_alias | split row ' ' | take 1)
  } else {
    $spans
  }

  match $spans.0 {
    nu => $fish_completer
    git => $fish_completer
    _ => $carapace_completer
  } | do $in $spans
}

$env.config = {
  show_banner: false,
  history: {
    file_format: "sqlite"
    isolation: true
  }
  completions: {
    external: {
      enable: true
      completer: $external_completer
    }
  }
  hooks: {
    pre_prompt: [{ print -n $"(ansi title)($user)@($hostname):(pwd) $(ansi st)" }]
    pre_execution: [
      { print -n $"(ansi title)($user)@($hostname):(pwd) > (commandline)(ansi st)" }
      $load_direnv
    ]
    env_change: {
      PWD: [{|before, after| do $load_direnv }]
    }
  }
}
$env.PATH = (
  $env.PATH |
  split row (char esep) |
  prepend /home/myuser/.apps |
  append /usr/bin/env
)

# aliases
def lsm [] { ls | sort-by modified }
def psf [name] { ps | where name =~ $name }
