#!/usr/bin/env bash
set -euo pipefail

git_name="${GIT_NAME:-}"
git_email="${GIT_EMAIL:-}"
run_macos=false

usage() {
  cat <<'EOF'
Usage: ./init.sh [options]

Options:
  --name="Your Name"      Git user.name for this machine
  --email="you@example"   Git user.email for this machine
  --macos                 Run macOS post-setup after apply
  -h, --help              Show this help

Environment:
  GIT_NAME
  GIT_EMAIL
EOF
  exit 0
}

info() { printf '\033[1;34m[INFO]\033[0m %s\n' "$1" }

success() { printf '\033[1;32m[SUCCESS]\033[0m %s\n' "$1" }

error() { printf '\033[1;31m[ERROR]\033[0m %s\n' "$1" >&2 }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name=*)
      git_name="${1#*=}"
      ;;
    --email=*)
      git_email="${1#*=}"
      ;;
    --macos)
      run_macos=true
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

prompt_if_empty() {
  local label="$1"
  local value="$2"

  if [[ -n "${value}" ]]; then
    printf '%s' "${value}"
    return
  fi

  local input=""
  read -r -p "${label}: " input
  printf '%s' "${input}"
}

escape_toml() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

write_local_chezmoi_config() {
  local config_dir="${HOME}/.config/chezmoi"
  local config_file="${config_dir}/chezmoi.toml"

  mkdir -p "${config_dir}"

  cat > "${config_file}" <<EOF
[data]
name = "$(escape_toml "${git_name}")"
email = "$(escape_toml "${git_email}")"
EOF
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

  git_name="$(prompt_if_empty "Git name" "${git_name}")"
  git_email="$(prompt_if_empty "Git email" "${git_email}")"

  write_local_chezmoi_config
  apply_dotfiles
  run_macos_post_setup

  success "Bootstrap complete."
  success "Git identity is now managed through chezmoi and rendered into ~/.gitconfig"
}

main "$@"
