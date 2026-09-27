# ~/.config/zsh/status.zsh

# Agent/usage status stays asynchronous and uses the existing cache paths.
# One advisory lock coordinates all tabs; an attempt timestamp throttles
# failures too. No SSH/API call or lock wait occurs in the foreground.
if [[ -x "$HOME/.config/tmux/scripts/status-agents.sh" ]] \
  && zmodload zsh/datetime \
  && zmodload -F zsh/stat b:zstat \
  && zmodload -F zsh/system b:zsystem \
  && zsystem supports flock; then

  _status_cache_due() {
    local -a stamp
    zstat -A stamp +mtime \
      "${XDG_CACHE_HOME:-$HOME/.cache}/tmux/.refresh-attempt" \
      2>/dev/null || return 0

    (( EPOCHSECONDS - stamp[1] >= 10 || EPOCHSECONDS < stamp[1] ))
  }

  # A subshell guarantees the lock is released when this worker exits.
  _status_cache_refresh() (
    emulate -L zsh
    setopt PIPE_FAIL

    local d="${XDG_CACHE_HOME:-$HOME/.cache}/tmux"
    local s="$HOME/.config/tmux/scripts"
    local script cache tmp

    command mkdir -p -- "$d" || return
    : >> "$d/.refresh.lock" || return

    zsystem flock -t 0 "$d/.refresh.lock" 2>/dev/null || return

    _status_cache_due || return
    : >| "$d/.refresh-attempt" || return

    for script cache in \
      status-agents.sh agents \
      status-usage.sh limits
    do
      [[ -x "$s/$script" ]] || continue

      tmp="$d/$cache.txt.$$"

      if "$s/$script" |
        sed 's/#\[[^]]*\]//g' >| "$tmp"; then

        command mv -f -- "$tmp" "$d/$cache.txt"
      else
        # A failed producer must not erase the last useful cached value.
        command rm -f -- "$tmp"
      fi
    done
  )

  _status_cache_precmd() {
    _status_cache_due || return 0
    _status_cache_refresh </dev/null >/dev/null 2>&1 &!
    return 0
  }

  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _status_cache_precmd
fi
