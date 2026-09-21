#!/usr/bin/env sh
# Keep a Linux workstation (evo-dev) on the tip of main without a person at
# the keyboard: dotfiles through chezmoi, then Verk through its own guarded
# installer. Run by follow-main.timer (~/.config/systemd/user); by hand:
#   follow-main.sh            # both
#   follow-main.sh dotfiles   # or: verk
# Nothing here forces anything. A dirty or non-master dotfiles checkout is
# reported and left alone, and Verk's install-linux.sh refuses under a
# running chat turn (exit 3) or another install (exit 4); the next tick tries
# again. Logs: journalctl --user -u follow-main.
set -eu
what=${1:-all}

dotfiles() {
  src=$(chezmoi source-path)/..
  if [ -n "$(git -C "$src" status --porcelain)" ]; then
    echo "dotfiles: $src has local changes; not pulling" >&2
    return 0
  fi
  if [ "$(git -C "$src" branch --show-current)" != master ]; then
    echo "dotfiles: $src is not on master; not pulling" >&2
    return 0
  fi
  before=$(git -C "$src" rev-parse HEAD)
  # Install scripts stay excluded on Linux, as at bootstrap: the account has
  # no sudo and package installs belong to the evo development role.
  chezmoi update --exclude=scripts
  after=$(git -C "$src" rev-parse HEAD)
  if [ "$before" != "$after" ]; then
    echo "dotfiles: $before -> $after applied"
    systemctl --user daemon-reload
  fi
}

verk() {
  repo="$HOME/code/verk"
  [ -d "$repo/.git" ] || return 0
  if [ -n "$(git -C "$repo" status --porcelain)" ]; then
    echo "verk: $repo has local changes; not pulling" >&2
    return 0
  fi
  git -C "$repo" pull -q --ff-only
  head=$(git -C "$repo" rev-parse HEAD)
  if [ "$head" = "$(cat "$HOME/.verk/installed.commit" 2>/dev/null)" ]; then
    return 0
  fi
  echo "verk: installing $head"
  # Builds go through Depot's cache; mise supplies the pinned Go and Bun.
  rc=0
  (cd "$repo" && mise exec -- depot exec -- ./scripts/install-linux.sh) || rc=$?
  case $rc in
    0) ;;
    3 | 4) echo "verk: install refused (exit $rc); trying again next tick" ;;
    *) echo "verk: install failed (exit $rc)" >&2; return "$rc" ;;
  esac
}

case $what in
  all) dotfiles; verk ;;
  dotfiles) dotfiles ;;
  verk) verk ;;
  *) echo "usage: follow-main.sh [all|dotfiles|verk]" >&2; exit 2 ;;
esac
