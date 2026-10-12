#!/usr/bin/env sh
# Keep managed configuration current on a Linux workstation.
# Run by follow-main.timer, or by hand with follow-main.sh [dotfiles].
# Dirty or non-master checkouts are left alone.
set -eu
case ${1:-dotfiles} in
  dotfiles) ;;
  *) echo "usage: follow-main.sh [dotfiles]" >&2; exit 2 ;;
esac
[ "$#" -le 1 ] || { echo "usage: follow-main.sh [dotfiles]" >&2; exit 2; }

src=$(git -C "$(chezmoi source-path)" rev-parse --show-toplevel)
if [ -n "$(git -C "$src" status --porcelain)" ]; then
  echo "dotfiles: $src has local changes; not pulling" >&2
  exit 0
fi
if [ "$(git -C "$src" branch --show-current)" != master ]; then
  echo "dotfiles: $src is not on master; not pulling" >&2
  exit 0
fi
before=$(git -C "$src" rev-parse HEAD)
# Package installs remain a separate machine bootstrap step.
chezmoi update --exclude=scripts
after=$(git -C "$src" rev-parse HEAD)
if [ "$before" != "$after" ]; then
  echo "dotfiles: $before -> $after applied"
  systemctl --user daemon-reload
fi
