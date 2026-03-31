#!/usr/bin/env bash
set -euo pipefail

input=$(cat)

# Only trigger on git commit commands
is_commit=$(echo "$input" | jq -r '.tool_input.command' 2>/dev/null | grep -c '^git commit' || true)

if [[ "$is_commit" -gt 0 ]]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"[post-commit] A commit was just made. Run the /progress skill now to update or create progress.md. Do NOT ask the user — just run it."}}'
fi
