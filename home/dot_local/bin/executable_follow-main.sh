#!/usr/bin/env sh
# Keep a Linux workstation (evo-dev) on the tip of main without a person at
# the keyboard: dotfiles through chezmoi, then Verk through its own guarded
# installer. Run by follow-main.timer (~/.config/systemd/user); by hand:
#   follow-main.sh            # both
#   follow-main.sh dotfiles   # or: verk
# Nothing here forces anything. A dirty or non-master dotfiles checkout, or a
# managed file edited since chezmoi last wrote it, is reported and left alone;
# a dirty or non-main Verk checkout likewise. Verk's install-linux.sh refuses
# under a running chat turn (exit 3) or another install (exit 4); the next tick
# tries again. The two steps are independent: one skipping or failing does not
# stop the other, and the exit status is the last failure.
# Logs: journalctl --user -u follow-main.
#
# set -e is suspended inside a function called as `f || ...`, so every
# command in the steps below checks its own status.
set -eu
what=${1:-all}

dotfiles() {
  src=$(chezmoi source-path) || return
  src=$src/..
  changes=$(git -C "$src" status --porcelain) || return
  if [ -n "$changes" ]; then
    echo "dotfiles: $src has local changes; not pulling" >&2
    return 0
  fi
  branch=$(git -C "$src" branch --show-current) || return
  if [ "$branch" != master ]; then
    echo "dotfiles: $src is not on master; not pulling" >&2
    return 0
  fi
  # The first status column compares a target with what chezmoi last wrote
  # there. Anything but a space means it was edited, created or deleted by
  # hand, and apply would ask before overwriting it; with no terminal that
  # question fails. Leave the edit for a person instead.
  status=$(chezmoi status --exclude=scripts) || return
  drift=$(printf '%s\n' "$status" | awk 'NF && substr($0, 1, 1) != " "') || return
  if [ -n "$drift" ]; then
    echo "dotfiles: targets changed since chezmoi last wrote them; not updating:" >&2
    printf '%s\n' "$drift" >&2
    return 0
  fi
  before=$(git -C "$src" rev-parse HEAD) || return
  # Install scripts stay excluded on Linux, as at bootstrap: the account has
  # no sudo and package installs belong to the evo development role. An edit
  # made after the check above fails the prompt here rather than waiting.
  chezmoi update --exclude=scripts --no-tty </dev/null || return
  after=$(git -C "$src" rev-parse HEAD) || return
  if [ "$before" != "$after" ]; then
    echo "dotfiles: $before -> $after applied"
    systemctl --user daemon-reload || return
  fi
}

verk() {
  repo="$HOME/code/verk"
  [ -d "$repo/.git" ] || return 0
  changes=$(git -C "$repo" status --porcelain) || return
  if [ -n "$changes" ]; then
    echo "verk: $repo has local changes; not pulling" >&2
    return 0
  fi
  branch=$(git -C "$repo" branch --show-current) || return
  if [ "$branch" != main ]; then
    echo "verk: $repo is not on main; not pulling" >&2
    return 0
  fi
  git -C "$repo" pull -q --ff-only || return
  head=$(git -C "$repo" rev-parse HEAD) || return
  if [ "$head" = "$(cat "$HOME/.verk/installed.commit" 2>/dev/null)" ]; then
    return 0
  fi
  echo "verk: installing $head"
  # Builds go through Depot's cache; mise supplies the pinned Go and Bun.
  install_rc=0
  (cd "$repo" && mise exec -- depot exec -- ./scripts/install-linux.sh) || install_rc=$?
  case $install_rc in
    0) ;;
    3 | 4) echo "verk: install refused (exit $install_rc); trying again next tick" ;;
    *) echo "verk: install failed (exit $install_rc)" >&2; return "$install_rc" ;;
  esac
}

rc=0
case $what in
  all) dotfiles || rc=$?; verk || rc=$? ;;
  dotfiles) dotfiles || rc=$? ;;
  verk) verk || rc=$? ;;
  *) echo "usage: follow-main.sh [all|dotfiles|verk]" >&2; exit 2 ;;
esac
exit "$rc"
