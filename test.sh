#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

fail() {
  printf '[ERROR] %s\n' "$1" >&2
  exit 1
}

section() {
  printf '\n==> %s\n' "$1"
}

section "Checking required tools"

command -v shellcheck >/dev/null 2>&1 || fail "shellcheck is required"
command -v chezmoi >/dev/null 2>&1 || fail "chezmoi is required"

section "Running shellcheck"

mapfile -d '' shell_files < <(
  find . \
    -type f \
    -name '*.sh' \
    -not -path './.git/*' \
    -print0
)

if [[ ${#shell_files[@]} -gt 0 ]]; then
  shellcheck "${shell_files[@]}"
fi

section "Checking executable scripts"

[[ -x ./init.sh ]] || fail "init.sh must be executable"
[[ -x ./test.sh ]] || fail "test.sh must be executable"

section "Testing chezmoi config template"

rendered_config="$(mktemp "${TMPDIR:-/tmp}/chezmoi.XXXXXX.toml")"

chezmoi execute-template \
  --init \
  --promptString 'name=CI' \
  --promptString 'email=ci@example.invalid' \
  --promptString 'signingKey=' \
  < home/.chezmoi.toml.tmpl \
  > "${rendered_config}"

cat "${rendered_config}"

chezmoi --config "${rendered_config}" data >/dev/null

grep -q '^name = "CI"$' "${rendered_config}" || fail "generated config missing CI name"
grep -q '^email = "ci@example.invalid"$' "${rendered_config}" || fail "generated config missing CI email"

if grep -q '^signingKey =' "${rendered_config}"; then
  fail "empty signingKey should not be rendered"
fi

section "Testing chezmoi dry-run apply"

chezmoi init \
  --source="${PWD}" \
  --apply \
  --dry-run \
  --keep-going \
  --promptString 'name=CI' \
  --promptString 'email=ci@example.invalid' \
  --promptString 'signingKey='

section "All tests passed"
