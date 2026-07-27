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

# No mapfile: must also run on macOS' bash 3.2
shell_files=()
while IFS= read -r -d '' f; do
  shell_files+=("$f")
done < <(
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

rendered_config="$(mktemp "${TMPDIR:-/tmp}/chezmoi.XXXXXX").toml"

# An empty config keeps promptStringOnce from picking up an existing
# machine config, so the assertions below are deterministic everywhere.
empty_config="$(mktemp "${TMPDIR:-/tmp}/chezmoi-empty.XXXXXX").toml"
touch "${empty_config}"

chezmoi execute-template \
  --config "${empty_config}" \
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
grep -q '^signingKey = ""$' "${rendered_config}" || fail "empty signingKey should render as empty string"
grep -q '^personal = true$' "${rendered_config}" || fail "default profile should be personal"
grep -q '^work = false$' "${rendered_config}" || fail "work should default to false"

section "Testing WORK profile selection"

rendered_work_config="$(mktemp "${TMPDIR:-/tmp}/chezmoi-work.XXXXXX").toml"

WORK=true chezmoi execute-template \
  --config "${empty_config}" \
  --init \
  --promptString 'name=CI' \
  --promptString 'email=ci@example.invalid' \
  --promptString 'signingKey=' \
  < home/.chezmoi.toml.tmpl \
  > "${rendered_work_config}"

grep -q '^profile = "work"$' "${rendered_work_config}" || fail "WORK=true should select the work profile"
grep -q '^work = true$' "${rendered_work_config}" || fail "WORK=true should set work = true"
grep -q '^personal = false$' "${rendered_work_config}" || fail "WORK=true should set personal = false"

section "Testing chezmoi dry-run apply"

chezmoi init \
  --source="${PWD}" \
  --apply \
  --dry-run \
  --force \
  --keep-going \
  --promptString 'name=CI' \
  --promptString 'email=ci@example.invalid' \
  --promptString 'signingKey='

section "All tests passed"
