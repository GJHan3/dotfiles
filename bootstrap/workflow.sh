#!/usr/bin/env bash

clone_or_update_repo() {
  local repo_url=$1 target_dir=$2
  if [[ -d "${target_dir}/.git" ]]; then
    if should_update_existing; then
      if [[ -n "$(git -C "$target_dir" status --porcelain)" ]]; then
        print_warning "Repository update skipped" "Local changes exist in ${target_dir}; preserving them instead of running git pull."
        return 0
      fi
      git -C "$target_dir" pull --ff-only
    fi
  else
    mkdir -p "$(dirname "$target_dir")"
    git clone --depth=1 "$repo_url" "$target_dir"
  fi
}

install_shell_framework() {
  local failed=0
  tool_selected shell-framework || return 0
  clone_or_update_repo https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR" || failed=1
  clone_or_update_repo https://github.com/romkatv/powerlevel10k.git "$P10K_DIR" || failed=1
  clone_or_update_repo https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGESTIONS_DIR" || failed=1
  clone_or_update_repo https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_SYNTAX_HIGHLIGHTING_DIR" || failed=1
  return "$failed"
}

install_meslo_fonts() {
  local font_dir=$1 file encoded_file failed=0
  local base_url=https://github.com/romkatv/powerlevel10k-media/raw/master
  local -a files=("MesloLGS NF Regular.ttf" "MesloLGS NF Bold.ttf" "MesloLGS NF Italic.ttf" "MesloLGS NF Bold Italic.ttf")

  tool_selected fonts || return 0
  if [[ $FORCE_INSTALL -eq 0 ]]; then
    local all_present=1
    for file in "${files[@]}"; do
      [[ -f "${font_dir}/${file}" ]] || all_present=0
    done
    (( all_present == 0 )) || return 0
  fi
  mkdir -p "$font_dir" || return 1
  for file in "${files[@]}"; do
    encoded_file=${file// /%20}
    curl -fsSL "${base_url}/${encoded_file}" -o "${font_dir}/${file}" || failed=1
  done
  if [[ "$CURRENT_OS" == ubuntu ]] && need_cmd fc-cache; then
    fc-cache -f "$font_dir" || failed=1
  fi
  return "$failed"
}

ensure_codex_xauthority_bridge() {
  mkdir -p "${HOME}/.codex-home"
  ln -sfn "${HOME}/.Xauthority" "${HOME}/.codex-home/.Xauthority"
}

set_default_shell_to_zsh() {
  local zsh_path reply
  zsh_path="$(command -v zsh)"
  [[ "${SHELL:-}" != "$zsh_path" ]] || return 0
  if [[ $INTERACTIVE -eq 1 ]]; then
    printf 'Set default shell to %s? [Y/n] ' "$zsh_path"
    read -r reply
    reply=${reply:-Y}
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      if ! run_sudo chsh -s "$zsh_path" "$USER"; then
        print_warning "Default shell unchanged" "Could not set the default shell to ${zsh_path}."
      fi
    fi
  fi
}

configure_git_identity() {
  local current_name current_email git_name git_email reply
  current_name="$(git config --global user.name || true)"
  current_email="$(git config --global user.email || true)"
  [[ -z "$current_name" || -z "$current_email" ]] || return 0
  [[ $INTERACTIVE -eq 1 ]] || return 0
  printf 'Configure global git user.name and user.email now? [Y/n] '
  read -r reply
  reply=${reply:-Y}
  [[ "$reply" =~ ^[Yy]$ ]] || return 0
  if [[ -z "$current_name" ]]; then
    printf 'Git user.name: '
    read -r git_name
    [[ -z "$git_name" ]] || git config --global user.name "$git_name"
  fi
  if [[ -z "$current_email" ]]; then
    printf 'Git user.email: '
    read -r git_email
    [[ -z "$git_email" ]] || git config --global user.email "$git_email"
  fi
}

print_post_install_notes() {
  if command_runs codex --version; then
    print_status_header NEXT "Codex CLI"
    print_command_hint "Run:" codex
    print_command_hint "Or:" "codex login"
    printf '  Sign in with your ChatGPT account or API key.\n'
  else
    print_missing_command_warning "Codex CLI" codex "Codex terminal workflows are unavailable until it is installed." "npm i -g @openai/codex@latest"
  fi
  if command_runs opencode --version; then
    print_status_header NEXT "OpenCode CLI"
    print_command_hint "Run:" opencode
    print_command_hint "Optional:" "opencode auth login"
    printf '  Sign in with the model provider you want to use, then start a session.\n'
  else
    print_missing_command_warning "OpenCode CLI" opencode "OpenCode terminal workflows are unavailable until it is installed." "npm i -g opencode-ai@latest"
  fi
  if command_runs claude --version; then
    print_status_header NEXT "Claude Code CLI"
    print_command_hint "Run:" claude
    printf '  Sign in with your Anthropic account when prompted, then start a session.\n'
  else
    print_missing_command_warning "Claude Code CLI" claude "Claude Code is unavailable until it is installed." "npm i -g @anthropic-ai/claude-code@latest"
  fi
  if command_runs lark-cli --version; then
    print_status_header NEXT "Lark CLI"
    print_command_hint "Run:" "lark-cli config init --new"
    print_command_hint "Optional:" "lark-cli auth login"
    printf '  Use the optional login if you want user-level access.\n'
  else
    print_missing_command_warning "Lark CLI" lark-cli "Feishu/Lark command workflows are unavailable until it is installed." "npm i -g @larksuite/cli@latest"
  fi
  if command_runs whiteboard-cli --help; then
    print_status_header NEXT "Lark Whiteboard CLI"
    print_command_hint "Run:" "whiteboard-cli --help"
    printf '  Use it with lark-cli for Feishu/Lark whiteboard rendering.\n'
  else
    print_missing_command_warning "Lark Whiteboard CLI" whiteboard-cli "Whiteboard rendering workflows are unavailable until it is installed." "npm i -g @larksuite/whiteboard-cli@latest"
  fi
  if need_cmd sshfs; then
    print_status_header INFO "SSHFS for Yazi is ready"
    [[ "$CURRENT_OS" != macos ]] || printf '  If mounts are blocked, allow macFUSE in System Settings -> Privacy & Security.\n'
  fi
  if need_cmd tailscale || [[ -d /Applications/Tailscale.app ]]; then
    print_status_header NEXT Tailscale
    if [[ "$CURRENT_OS" == macos ]]; then
      print_command_hint "Open:" "open -a Tailscale"
      printf '  Sign in from the macOS app and allow the VPN/network extension if prompted.\n'
    else
      print_command_hint "Join tailnet:" "sudo tailscale up"
    fi
    print_command_hint "List devices:" "tailscale status"
    print_command_hint "Check this IP:" "tailscale ip -4"
    print_command_hint "SSH example:" "ssh <user>@<tailscale-ip-or-magicdns-name>"
    print_command_hint "Check SSH port:" "nc -vz <tailscale-ip> 22"
    printf '  If ping works but SSH hangs, verify sshd and port 22 on the target.\n'
    printf "  Read Tailscale's subnet-router guide before exposing a whole LAN.\n"
  else
    print_missing_command_warning Tailscale tailscale "Private network access is unavailable until it is installed." "https://tailscale.com/download"
  fi
  print_status_header INFO Font
  printf '  If Powerlevel10k icons look wrong, set the terminal font to MesloLGS NF.\n'
  if need_cmd zsh; then
    print_status_header INFO Proxy
    print_command_hint "Run when needed:" proxy_on
    printf '  Proxy is off by default.\n'
  fi
}
