#!/bin/sh
# Fresh-machine bootstrap for macOS and Linux: installs chezmoi into
# ~/.local/bin when missing, then clones and applies this repository.
#
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/froppa/dotfiles/master/bootstrap.sh)"
#
# Run through sh -c, not "curl | sh", so chezmoi's Git identity prompts can
# read the terminal. GIT_NAME and GIT_EMAIL skip those prompts, WORK=true
# selects the work profile, DOTFILES_REPO overrides the GitHub repository.
set -eu

repo=${DOTFILES_REPO:-froppa/dotfiles}
bin="$HOME/.local/bin"

info() { printf '\033[1;34m[INFO]\033[0m %s\n' "$1"; }
fail() { printf '\033[1;31m[ERROR]\033[0m %s\n' "$1" >&2; exit 1; }

case $(uname -s) in
  Darwin) os=macos ;;
  Linux) os=linux ;;
  *) fail "unsupported OS: $(uname -s)" ;;
esac
info "Bootstrapping $repo on $os"

command -v curl > /dev/null 2>&1 || fail "curl is required"
if ! command -v git > /dev/null 2>&1; then
  if [ "$os" = macos ]; then
    info "Installing the Xcode command line tools for git; rerun when done"
    xcode-select --install
    exit 1
  fi
  fail "git is required (apt install git / dnf install git)"
fi

mkdir -p "$bin"
export PATH="$bin:$PATH"
if ! command -v chezmoi > /dev/null 2>&1; then
  info "Installing chezmoi into $bin"
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$bin"
fi

set -- init --apply "$repo"
[ -n "${GIT_NAME:-}" ] && set -- "$@" --promptString "name=$GIT_NAME"
[ -n "${GIT_EMAIL:-}" ] && set -- "$@" --promptString "email=$GIT_EMAIL"
info "Running chezmoi $*"
chezmoi "$@"

if [ "$os" = macos ] && [ -t 0 ]; then
  printf 'Apply the macOS defaults now? [y/N] '
  read -r answer
  case $answer in
    y|Y) bash "$(chezmoi source-path)/macos-scripts/macos-defaults.sh" ;;
  esac
fi
info "Done. Open a new shell, or run: exec zsh"
