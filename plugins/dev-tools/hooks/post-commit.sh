#!/usr/bin/env bash
set -euo pipefail

input=$(cat)

# Only trigger on git commit commands
is_commit=$(echo "$input" | jq -r '.tool_input.command' 2>/dev/null | grep -c '^git commit' || true)

if [[ "$is_commit" -gt 0 ]]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"[post-commit] A commit was just made. If progress.md exists in this project, update it now: check off completed tasks, add new decisions, note any warnings for the next session. Read progress.md first, then Edit it. If progress.md does NOT exist and a non-trivial feature is in progress, create it following the /progress skill format. Do NOT ask the user what was done — analyze the session context yourself."}}'
fi
