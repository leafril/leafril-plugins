#!/usr/bin/env bash
set -euo pipefail

input=$(cat)

# Only trigger on git commit commands
is_commit=$(echo "$input" | grep -c 'git commit' || true)

if [[ "$is_commit" -gt 0 ]]; then
  echo "[post-commit] A commit was just made. Run the /progress skill now to update or create progress.json. Do NOT ask the user — just run it." >&2
  exit 2
fi
