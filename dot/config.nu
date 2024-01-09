let load_direnv = {
  if (which direnv | is-empty) { return }
  direnv export json | from json | default {} | load-env
}
let user = (whoami)
let hostname = (hostname)
$env.config = {
  show_banner: false,
  history: {
    # I want history isolation, but that's only available with sqlite.
    file_format: "sqlite"
    history_isolation: true # default?
  }
  completions: {
    case_sensitive: false # case-sensitive completions
    quick: true    # set to false to prevent auto-selecting completions
    partial: true    # set to false to prevent partial filling of the prompt
    algorithm: "fuzzy"    # prefix or fuzzy
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
