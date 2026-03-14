# Use Powerlevel10k's lean preset as the default baseline.
if [[ -r "$HOME/.oh-my-zsh/custom/themes/powerlevel10k/config/p10k-lean.zsh" ]]; then
  source "$HOME/.oh-my-zsh/custom/themes/powerlevel10k/config/p10k-lean.zsh"
fi

typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false

typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  context
  dir
  vcs
  newline
  prompt_char
)

typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status
  command_execution_time
  background_jobs
  direnv
  asdf
  virtualenv
  anaconda
  pyenv
  goenv
  nodenv
  nvm
  nodeenv
  rbenv
  rvm
  fvm
  luaenv
  jenv
  plenv
  perlbrew
  phpenv
  scalaenv
  haskell_stack
  kubecontext
  terraform
  aws
  aws_eb_env
  azure
  gcloud
  google_app_cred
  toolbox
  nordvpn
  ranger
  yazi
  nnn
  lf
  xplr
  vim_shell
  midnight_commander
  nix_shell
  chezmoi_shell
  todo
  timewarrior
  taskwarrior
  per_directory_history
  newline
)

typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='%n@%m'
typeset -g POWERLEVEL9K_CONTEXT_DEFAULT_CONTENT_EXPANSION='%n@%m'
typeset -g POWERLEVEL9K_CONTEXT_SUDO_CONTENT_EXPANSION='%n@%m'
