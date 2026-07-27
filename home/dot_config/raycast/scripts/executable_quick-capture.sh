#!/usr/bin/env bash
#
# @raycast.schemaVersion 1
# @raycast.title Quick Capture
# @raycast.mode silent
# @raycast.packageName Personal Productivity
# @raycast.icon 📝
# @raycast.description Capture a todo, reminder, or note from Raycast quickly.
#
# @raycast.argument1 {
#   "type": "dropdown",
#   "placeholder": "Type",
#   "default": "todo",
#   "data": [
#     {
#       "title": "Todo",
#       "value": "todo"
#     },
#     {
#       "title": "Reminder",
#       "value": "reminder"
#     },
#     {
#       "title": "Note",
#       "value": "note"
#     }
#   ]
# }
#
# @raycast.argument2 {
#   "type": "text",
#   "placeholder": "What needs to be captured?",
#   "default": ""
# }
#
# @raycast.argument3 {
#   "type": "text",
#   "placeholder": "Due date/time (optional for reminders, e.g. tomorrow 9am)",
#   "optional": true
# }

set -euo pipefail

TYPE="${1:-todo}"
CONTENT="${2:-}"
DUE_RAW="${3:-}"

if [[ -z "$CONTENT" ]]; then
  echo "No content provided."
  exit 1
fi

normalize_type() {
  local t="$1"
  case "$t" in
    todo|todo*) echo todo ;;
    rem* ) echo reminder ;;
    note*|memo* ) echo note ;;
    * ) echo "$t" ;;
  esac
}

TYPE="$(normalize_type "$TYPE")"

VAULT="${AGENT_WORKSPACE_VAULT:-$HOME/code/agent-workspace}"
INBOX_DIR="$VAULT/Inbox"
DATE_ONLY="$(date '+%Y-%m-%d')"
STAMP="$(date '+%Y-%m-%d-%H%M')"

slugify() {
  local s="$1"
  s="$(printf '%s' "$s" | tr '\n' ' ')"
  s="$(printf '%s' "$s" | sed -E 's#[/:*?"<>|]#-#g; s/[[:space:]]+/ /g; s/^[[:space:]-]+//; s/[[:space:]-]+$//')"
  s="${s:0:60}"
  [[ -z "$s" ]] && s="capture"
  printf '%s' "$s"
}

create_inbox_note() {
  local kind="$1"
  local title="$2"
  local slug file
  slug="$(slugify "$title")"
  file="$INBOX_DIR/${STAMP} ${slug}.md"
  mkdir -p "$INBOX_DIR"

  case "$kind" in
    note)
      cat >"$file" <<NOTE
---
kind: note
created: $DATE_ONLY
tags: []
---

# $title
NOTE
      ;;
    task)
      cat >"$file" <<TASK
---
kind: task
status: triage
project:
source_root:
created: $DATE_ONLY
tags: []
---

# $title

## Outcome

One observable outcome.

## Notes

## Triage

- [ ] Set \`project\` to a folder under \`contexts/\`.
- [ ] Promote to \`contexts/<branch>/<project>/tasks/<slug>.md\` using
      \`templates/task.md\`, or drop this note.
TASK
      ;;
  esac
}

case "$TYPE" in
  todo)
    create_inbox_note "task" "$CONTENT"
    ;;

  note)
    create_inbox_note "note" "$CONTENT"
    ;;

  reminder)
    osascript - "$CONTENT" "$DUE_RAW" <<'APPLESCRIPT'
on run argv
  set reminderText to item 1 of argv
  set dueText to item 2 of argv

  tell application "Reminders"
    if (count of lists whose name is "Raycast") = 0 then
      make new list with properties {name:"Raycast"}
    end if
    set reminderList to first list whose name is "Raycast"

    if dueText is not "" then
      try
        set dueDate to date dueText
        make new reminder in reminderList with properties {name:reminderText, due date:dueDate}
      on error
        make new reminder in reminderList with properties {name:reminderText, body:dueText}
      end try
    else
      make new reminder in reminderList with properties {name:reminderText}
    end if
  end tell
end run
APPLESCRIPT
    ;;

  *)
    echo "Invalid capture type: $TYPE"
    exit 1
    ;;
esac

exit 0
