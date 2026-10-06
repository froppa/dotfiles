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
command -v python3 >/dev/null 2>&1 || fail "python3 is required"
command -v zsh >/dev/null 2>&1 || fail "zsh is required"

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

# Hammerspoon embeds Lua 5.4; LuaJIT (nvim -l) rejects its bitwise operators.
if command -v luac >/dev/null 2>&1; then
  section "Checking Hammerspoon Lua syntax"
  luac -p home/dot_hammerspoon/init.lua
fi

section "Checking executable scripts"

[[ -x ./init.sh ]] || fail "init.sh must be executable"
[[ -x ./test.sh ]] || fail "test.sh must be executable"
[[ -x ./bootstrap.sh ]] || fail "bootstrap.sh must be executable"

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
  < home/.chezmoi.toml.tmpl \
  > "${rendered_config}"

cat "${rendered_config}"

chezmoi --config "${rendered_config}" data >/dev/null

grep -q '^name = "CI"$' "${rendered_config}" || fail "generated config missing CI name"
grep -q '^email = "ci@example.invalid"$' "${rendered_config}" || fail "generated config missing CI email"
grep -q '^personal = true$' "${rendered_config}" || fail "default profile should be personal"
grep -q '^work = false$' "${rendered_config}" || fail "work should default to false"

section "Testing WORK profile selection"

rendered_work_config="$(mktemp "${TMPDIR:-/tmp}/chezmoi-work.XXXXXX").toml"

WORK=true chezmoi execute-template \
  --config "${empty_config}" \
  --init \
  --promptString 'name=CI' \
  --promptString 'email=ci@example.invalid' \
  < home/.chezmoi.toml.tmpl \
  > "${rendered_work_config}"

grep -q '^profile = "work"$' "${rendered_work_config}" || fail "WORK=true should select the work profile"
grep -q '^work = true$' "${rendered_work_config}" || fail "WORK=true should set work = true"
grep -q '^personal = false$' "${rendered_work_config}" || fail "WORK=true should set personal = false"

section "Checking safe adoption defaults"

[[ -f home/dot_local/bin/symlink_depot.tmpl ]] || fail "Depot must resolve to the standalone Cargo installation"
grep -Fq '".cargo/bin/depot"' home/dot_local/bin/symlink_depot.tmpl || fail "Depot link must not target the legacy Verk binary"
grep -Fq 'source <(depot completions zsh 2>/dev/null)' home/dot_zsh_completions || fail "Depot completion must follow the installed version"

[[ -f home/create_dot_gitconfig.tmpl ]] || fail "Git defaults must be create-only"
[[ ! -e home/dot_gitconfig.tmpl ]] || fail "Git config must not overwrite an existing setup"
grep -Fq 'name = {{ .name | quote }}' home/create_dot_gitconfig.tmpl || fail "new machines must receive a Git name"
grep -Fq 'email = {{ .email | quote }}' home/create_dot_gitconfig.tmpl || fail "new machines must receive a Git email"
grep -Fq 'joinPath .chezmoi.homeDir ".config/git/dotfiles.gitconfig"' home/create_dot_gitconfig.tmpl || fail "root Git config must include managed defaults"
[[ -f home/dot_config/git/dotfiles.gitconfig.tmpl ]] || fail "managed Git defaults are missing"
grep -Fq "alias confgit='chezmoi edit --apply ~/.config/git/dotfiles.gitconfig'" home/dot_aliases || fail "confgit must edit managed defaults"
[[ ! -e home/dot_config/raycast/raycast.rayconfig ]] || fail "Raycast exports must not be managed"
[[ -f home/dot_config/ghostty/config ]] || fail "Ghostty config must be named config, the one path every Ghostty version reads"
grep -Fqx '.config/ghostty/config.ghostty' home/.chezmoiremove || fail "a stale config.ghostty would load beside the managed config"
grep -Fqx "alias ch='chezmoi'" home/dot_aliases || fail "ch must alias chezmoi"
grep -Fq 'herdr machine add evo-dev' home/.chezmoiscripts/run_after_60-add-herdr-evo-dev.sh.tmpl || fail "apply must register evo-dev as a saved herdr machine"
grep -Fq '{{ if and (eq .chezmoi.os "darwin") .personal -}}' home/.chezmoiscripts/run_after_60-add-herdr-evo-dev.sh.tmpl || fail "only the personal Mac may attach evo-dev"
grep -Fq 'command = /bin/zsh' home/dot_config/ghostty/config || fail "Ghostty must launch zsh; herdr is started on demand"
grep -Fq 'config-file = ?config.local' home/dot_config/ghostty/config || fail "Ghostty must load the optional machine-local override last"
! grep -qE '^keybind = (performable:)?ctrl\+alt\+super\+[^=]+=text:' home/dot_config/ghostty/config || fail "Hyper chords must reach herdr, not be rewritten into tmux prefix bytes"
! grep -qE '^keybind = ctrl\+alt\+super\+[^=]+=[^i]' home/dot_config/ghostty/config || fail "Hyper actions must be performable: a menu shortcut fires before the herdr key table"
grep -q 'activate_key_table:herdr' home/dot_zshrc || fail "the herdr wrapper must hand Ghostty's Hyper chords to herdr"
[[ "$(grep -oE '^keybind = (performable:)?ctrl\+alt\+super\+[^=]+' home/dot_config/ghostty/config | sed -E 's/^keybind = (performable:)?//' | grep -v '+equal$')" == "$(grep -E '^keybind = herdr/.+=unbind$' home/dot_config/ghostty/config | sed 's/^keybind = herdr\///; s/=unbind$//')" ]] || fail "the herdr key table must unbind every Hyper chord Ghostty binds"
[[ ! -e home/dot_config/ghostty/herdr.ghostty ]] || fail "herdr is the default; the herdr.ghostty overlay is gone"
grep -Fq "bind -n M-C-a if -F '#{@ssht}' 'send-keys M-C-a' 'switch-client -T prefix'" home/dot_config/tmux/tmux.conf || fail "Hyper chords must drive the remote tmux in an ssht pane"
grep -Fq 'tmux*:RGB:extkeys' home/dot_config/tmux/tmux.conf || fail "a remote tmux nested by ssht must get extended keys for Claude Code's Shift-Enter"
grep -Fq 'add-zsh-hook precmd _terminal_modes_reset' home/dot_config/zsh/terminal.zsh || fail "the prompt must switch off mouse and key reporting a dead program left on"
grep -Fq 'keybind = super+k=text:\x0c' home/dot_config/ghostty/config || fail "missing Command-K clear binding"
grep -Fq 'keybind = shift+enter=unbind' home/dot_config/ghostty/config || fail "legacy Shift-Enter paste binding must be removed"
[[ -f home/.chezmoiscripts/run_once_after_24-install-ghostty-terminfo.sh ]] || fail "Linux hosts must install an xterm-ghostty terminfo entry for plain ssh logins"
grep -Fq '      - ncurses-term' home/.chezmoidata/40-packages.yml || fail "ncurses-term must ship the ghostty terminfo that xterm-ghostty is derived from"
grep -Fq 'xterm-ghostty:RGB:extkeys' home/dot_config/tmux/tmux.conf || fail "Ghostty must advertise extended keys to tmux"
grep -Fq 'set -s extended-keys on' home/dot_config/tmux/tmux.conf || fail "tmux must pass modified keys to Claude Code"
grep -Fq 'set -g focus-events on' home/dot_config/tmux/tmux.conf || fail "tmux must pass focus events to Claude Code"
grep -Fq 'set -g assume-paste-time 0' home/dot_config/tmux/tmux.conf || fail "tmux must disable paste timing as a global session option"
grep -Fq '.local/bin/depot' home/.chezmoiignore || fail "the Depot symlink must not replace evo-dev's real binary on Linux"
sed -n '/ne .chezmoi.os "darwin"/,/end/p' home/.chezmoiignore | grep -Fq 'Library/LaunchAgents/com.froppa.clip-serve.plist' || fail "the clipboard LaunchAgent is macOS-only"
sed -n '/eq .chezmoi.os "darwin"/,/end/p' home/.chezmoiignore | grep -Fq '.local/bin/wl-paste' || fail "the wl-paste shim must not land on the Mac"
[[ -x home/dot_local/bin/executable_follow-main.sh && -f home/dot_config/systemd/user/follow-main.timer ]] || fail "follow-main must ship its script and timer for evo-dev"
sed -n '/eq .chezmoi.os "darwin"/,/end/p' home/.chezmoiignore | grep -Fq '.config/systemd' || fail "systemd user units must not be applied on macOS"
grep -Fq 'MouseDragEnd1Pane send -X copy-selection' home/dot_config/tmux/tmux.conf || fail "mouse selection must not snap the view back to the bottom"
grep -Fq 'xterm-ghostty:RGB:extkeys:hyperlinks' home/dot_config/tmux/tmux.conf || fail "tmux must pass OSC 8 hyperlinks through to Ghostty"
! grep -rqE '(^|[^a-z])evo(-|[^a-z]|$)|192\.168|100\.[0-9]+\.' home/dot_config/tmux || fail "host names and addresses belong in the unmanaged tmux *.local files"
if find home/private_dot_ssh -type f ! -name private_config.tmpl -print -quit | grep -q .; then
  fail "SSH key material must not be managed"
fi
[[ ! -e scripts/import-ssh-key.sh ]] || fail "SSH key import must not be supported"
[[ ! -e home/.chezmoiscripts/run_once_after_21-install-vim.sh ]] || fail "Vim setup must not invoke an unconfigured plugin manager"
! grep -Fq 'encryption = "age"' home/.chezmoi.toml.tmpl || fail "bootstrap must not depend on an age identity"
! grep -Fq -- '--exclude encrypted' README.md || fail "the documented install must apply cleanly without an age identity"
sed -n '/^  darwin:/,/^  personal:/p' home/.chezmoidata/40-packages.yml | grep -Fq -- '- xcode-build-server' || fail "xcode-build-server must be macOS-only"
grep -Fq '/usr/local/bin/brew' home/.chezmoiscripts/run_once_10-install-homebrew.sh || fail "Homebrew setup must support Intel macOS"

section "Testing Ubuntu and macOS bootstrap behavior"
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p 'test_*.py' -v

section "Testing fresh-home chezmoi dry-run apply"

fresh_home="$(mktemp -d "${TMPDIR:-/tmp}/chezmoi-home.XXXXXX")"

HOME="${fresh_home}" chezmoi init \
  --source="${PWD}" \
  --destination="${fresh_home}" \
  --apply \
  --dry-run \
  --force \
  --keep-going \
  --promptString 'name=CI' \
  --promptString 'email=ci@example.invalid'

section "All tests passed"
