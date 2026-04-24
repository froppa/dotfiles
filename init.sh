#!/usr/bin/env bash
set -euo pipefail

git_name="${GIT_NAME:-}"
git_email="${GIT_EMAIL:-}"
git_signing_key="${GIT_SIGNING_KEY:-}"
run_macos=false

usage() {
  cat <<'EOF'
Usage: ./init.sh [options]

Options:
  --name="Your Name"       Git user.name for this machine
  --email="you@example"    Git user.email for this machine
  --signing-key="KEY"      Git user.signingkey (SSH key / GPG key id)
  --macos                  Run macOS post-setup after apply
  -h, --help               Show this help

Environment:
  GIT_NAME
  GIT_EMAIL
  GIT_SIGNING_KEY

Notes:
  Values for name/email/signing-key are stored by chezmoi in
  ~/.config/chezmoi/chezmoi.toml the first time they're provided.
  Omit the flags on subsequent runs to reuse the stored values;
  chezmoi will prompt interactively if a value is still missing.
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
    --name=*)
      git_name="${1#*=}"
      ;;
    --email=*)
      git_email="${1#*=}"
      ;;
    --signing-key=*)
      git_signing_key="${1#*=}"
      ;;
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

ensure_local_bin_on_path() {
  case ":${PATH}:" in
    *":${HOME}/.local/bin:"*) ;;
    *) export PATH="${HOME}/.local/bin:${PATH}" ;;
  esac
}

ensure_chezmoi() {
  ensure_local_bin_on_path

  if command -v chezmoi >/dev/null 2>&1; then
    return
  fi

  info "Installing chezmoi..."
  mkdir -p "${HOME}/.local/bin"
  sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "${HOME}/.local/bin"
  ensure_local_bin_on_path

  command -v chezmoi >/dev/null 2>&1 || {
    error "chezmoi installation failed"
    exit 1
  }
}

apply_dotfiles() {
  if [[ ! -d .git || ! -d home ]]; then
    error "Run this from the dotfiles repo root"
    exit 1
  fi

  local args=(init --apply "${PWD}")
  [[ -n "${git_name}"        ]] && args+=(--promptString "name=${git_name}")
  [[ -n "${git_email}"       ]] && args+=(--promptString "email=${git_email}")
  [[ -n "${git_signing_key}" ]] && args+=(--promptString "signingKey=${git_signing_key}")

  info "Applying dotfiles from local repo..."
  chezmoi "${args[@]}"
}

run_macos_post_setup() {
  [[ "${run_macos}" == "true" ]] || return 0
  [[ "$(uname -s)" == "Darwin" ]] || return 0

  local script_path="./macos-scripts/macos-defaults.sh"
  if [[ -f "${script_path}" ]]; then
    info "Running macOS setup..."
    bash "${script_path}"
  fi
}

main() {
  info "Bootstrapping dotfiles..."

  ensure_chezmoi
  apply_dotfiles
  run_macos_post_setup

  success "Bootstrap complete."
  success "Git identity is now managed through chezmoi and rendered into ~/.gitconfig"
}

main "$@"
