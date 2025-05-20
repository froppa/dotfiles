#!/bin/bash
set -euo pipefail

echo "Running shellcheck on all shell scripts..."
ERRORS=()
while IFS= read -r -d '' f; do
  if ! shellcheck "$f"; then
    ERRORS+=("$f")
  else
    echo "[OK] Linted $f"
  fi
done < <(find . -type f -name '*.sh' -not -path './.git/*' -print0)

if [[ ${#ERRORS[@]} -ne 0 ]]; then
  echo "ShellCheck found issues in: ${ERRORS[*]}"
  exit 1
fi

echo "Testing chezmoi dry-run apply..."
CHEZMOI_CI=true chezmoi init \
  --source="${PWD}" \
  --apply \
  --dry-run \
  --keep-going || {
  echo "Error: chezmoi dry-run apply failed." >&2
  exit 1
}

export CHEZMOI_CI=false

echo "All tests passed."
