#!/bin/bash
set -euo pipefail

run_macos=false
usage() {
  cat <<EOF
Usage: $0 [--macos] [--profile=name]
  --macos        Run macOS configuration after applying dotfiles
  --profile=name Set profile (default: personal)
  -h, --help     Show this help message
EOF
  exit 0
}

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
  --macos) run_macos=true ;;
  # --profile=*) profile="${1#*=}" ;;
  -h | --help) usage ;;
  *) usage ;;
  esac
  shift
done

echo "🔧 Starting dotfiles install..."
if ! command -v chezmoi &>/dev/null; then
  # shellcheck disable=SC2312
  sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "${HOME}/.local/bin"
fi

if [[ -f ".chezmoiignore" && -f "setup.sh" ]]; then
  echo "📂 Local repo detected. Applying from current directory."
  chezmoi init --apply "${PWD}"
else
  echo "🌐 Applying from remote GitHub repo..."
  chezmoi init --apply "git@github.com:froppa/dotfiles.git"
fi

# --- macOS post-setup ---
if [[ "${run_macos}" == true ]]; then
  read -rp "macOS detected. Run macOS setup? (y/N) " -t 10 ok || ok="N"
  if [[ "${ok}" =~ ^[Yy]$ ]]; then
    script_path="./macos-scripts/macos-defaults.sh"
    if [[ -f "${script_path}" ]]; then
      echo "🛠 Running macOS setup..."
      bash "${script_path}"
    fi
  fi
fi

print_success() {
  echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

print_success "✅ Dotfiles installed."
