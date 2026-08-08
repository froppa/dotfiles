#!/usr/bin/env bash
set -euo pipefail

run_macos=false

usage() {
  cat <<'EOF'
Usage: ./init.sh [options]

Options:
  --macos                  Run macOS post-setup after apply
  -h, --help               Show this help

Notes:
  An existing ~/.gitconfig is preserved. On a new machine, the repository's
  defaults are created without setting a Git identity.
EOF
  exit 0
}

info() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$1"
}

success() {
  printf '\033[1;32m[SUCCESS]\033[0m %s\n' "$1"
}

error() {
  printf '\033[1;31m[ERROR]\033[0m %s\n' "$1" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --macos)
      run_macos=true
      ;;
    -h|--help)
      usage
      ;;
    *)
      usage
      ;;
  esac
  shift
done

ensure_chezmoi() {
  if command -v chezmoi >/dev/null 2>&1; then
    return
  fi

  info "Installing chezmoi..."
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"

  export PATH="$HOME/.local/bin:$PATH"

  command -v chezmoi >/dev/null 2>&1 || {
    error "chezmoi install failed"
    exit 1
  }
}

apply_dotfiles() {
  if [[ ! -d .git || ! -d home ]]; then
    error "Run this from the dotfiles repo root"
    exit 1
  fi

  info "Applying dotfiles from local repo..."
  chezmoi init --apply "${PWD}"
}

run_macos_post_setup() {
  if [[ "${run_macos}" != true ]]; then
    return
  fi

  if [[ "$(uname -s)" != "Darwin" ]]; then
    error "--macos was passed, but this is not macOS"
    exit 1
  fi

  if [[ -f ./macos-scripts/macos-defaults.sh ]]; then
    info "Running macOS post-setup..."
    bash ./macos-scripts/macos-defaults.sh
  else
    error "Missing ./macos-scripts/macos-defaults.sh"
    exit 1
  fi
}

main() {
  info "Bootstrapping dotfiles..."

  ensure_chezmoi
  apply_dotfiles
  run_macos_post_setup

  success "Dotfiles bootstrap complete."
}

main "$@"
