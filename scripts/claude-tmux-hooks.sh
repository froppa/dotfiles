#!/bin/sh
# Merge the tmux tab-state hooks into ~/.claude/settings.json (idempotent).
# Claude Code keeps that file itself, so it is not managed by chezmoi; run this
# once per machine after applying the dotfiles.
set -eu
settings="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
# shellcheck disable=SC2088 # Claude Code expands the tilde itself
script='~/.config/tmux/scripts/agent-state.sh'
[ -f "$settings" ] || printf '{}\n' > "$settings"
tmp=$(mktemp)
jq --arg s "$script" '
  def h(state): {"type":"command","command":($s + " " + state)};
  def without: map(select(.hooks | any(.command | startswith($s)) | not));
  .hooks //= {}
  | .hooks.UserPromptSubmit = (((.hooks.UserPromptSubmit // []) | without) + [{"hooks":[h("working")]}])
  | .hooks.PreToolUse = (((.hooks.PreToolUse // []) | without) + [{"hooks":[h("working")]}])
  | .hooks.Stop = (((.hooks.Stop // []) | without) + [{"hooks":[h("idle")]}])
  | .hooks.Notification = (((.hooks.Notification // []) | without) + [{"matcher":"permission_prompt|elicitation_dialog|agent_needs_input","hooks":[h("input")]}])
  | .hooks.SessionStart = (((.hooks.SessionStart // []) | without) + [{"hooks":[h("idle")]}])
  | .hooks.SessionEnd = (((.hooks.SessionEnd // []) | without) + [{"hooks":[h("off")]}])
' "$settings" > "$tmp"
mv "$tmp" "$settings"
printf 'tmux tab-state hooks installed in %s\n' "$settings"
