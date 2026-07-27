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
TIMESTAMP="$(date '+%Y-%m-%d %H:%M')"
OBSIDIAN_CAPTURE_FILE="${OBSIDIAN_CAPTURE_FILE:-$HOME/Documents/Obsidian/Inbox.md}"

append_obsidian() {
  local line_prefix="$1"
  mkdir -p "$(dirname "$OBSIDIAN_CAPTURE_FILE")"
  if [[ ! -f "$OBSIDIAN_CAPTURE_FILE" ]]; then
    : >"$OBSIDIAN_CAPTURE_FILE"
  fi
  printf "\n%s %s\n" "$line_prefix" "$CONTENT" >>"$OBSIDIAN_CAPTURE_FILE"
}

case "$TYPE" in
  todo)
    append_obsidian "- [ ] $TIMESTAMP — #todo"
    ;;

  note)
    append_obsidian "## 📝 $TIMESTAMP #note" \
    && printf "%s\n\n" "$CONTENT" >>"$OBSIDIAN_CAPTURE_FILE"
    ;;

  reminder)
    osascript - "$CONTENT" "$DUE_RAW" <<'APPLESCRIPT'
on run argv
  set reminderText to item 1 of argv
  set dueText to item 2 of argv

  tell application "Reminders"
    activate
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
