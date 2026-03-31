#!/usr/bin/env bash
set -euo pipefail

input=$(cat)

# Extract only the command field — avoid matching "git commit" in tool_output (e.g. diff results)
cmd=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null || true)

if [[ "$cmd" == git\ commit* ]]; then
  echo "[post-commit] A commit was just made. Run the /progress skill now to update or create progress.json. Do NOT ask the user — just run it." >&2
  exit 2
fi
