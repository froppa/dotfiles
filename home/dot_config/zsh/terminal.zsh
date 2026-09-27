# ~/.config/zsh/terminal.zsh
# Managed by chezmoi

# Recover from SSH/TUI applications that terminate without restoring
# terminal mouse, focus or extended-key reporting modes.
_terminal_modes_reset() {
  [[ -t 1 ]] || return 0

  print -n \
    '\e[?1000l' \
    '\e[?1002l' \
    '\e[?1003l' \
    '\e[?1005l' \
    '\e[?1006l' \
    '\e[?1015l' \
    '\e[?1004l' \
    '\e[>4m' \
    '\e[=0;1u'
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _terminal_modes_reset
