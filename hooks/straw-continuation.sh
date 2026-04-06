#!/usr/bin/env bash
# straw-continuation.sh — Stop hook
# Checks for active Straw plan with incomplete tasks.
# If tasks remain, outputs JSON to block exit and continue.
# If no active plan or all done, exits silently (allows stop).
# Always exits 0.
set -uo pipefail
trap 'exit 0' ERR

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Look for ACTIVE marker in current directory's .straw/plans/
active_file=".straw/plans/ACTIVE"

# No active plan — allow stop
if [ ! -f "$active_file" ]; then
  exit 0
fi

# Session isolation: only block the session that started the plan
STATE_SESSION=$(head -1 "$active_file" | jq -r '.session_id // empty' 2>/dev/null || true)
HOOK_SESSION=$(echo "$HOOK_INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
if [ -n "$STATE_SESSION" ] && [ -n "$HOOK_SESSION" ] && [ "$STATE_SESSION" != "$HOOK_SESSION" ]; then
  exit 0
fi

# Read the plan filename from ACTIVE
plan_name=$(head -1 "$active_file" | jq -r '.plan // empty' 2>/dev/null || cat "$active_file" | tr -d '[:space:]')
plan_file=".straw/plans/${plan_name}"

# ACTIVE file exists but plan file doesn't — clean up and allow stop
if [ ! -f "$plan_file" ]; then
  rm -f "$active_file"
  exit 0
fi

# Count total tasks (lines matching "- [ ]" or "- [x]")
total=$(grep -cE '^\s*- \[(x| )\]' "$plan_file" 2>/dev/null || echo 0)
completed=$(grep -cE '^\s*- \[x\]' "$plan_file" 2>/dev/null || echo 0)
remaining=$((total - completed))

if [ "$remaining" -gt 0 ]; then
  jq -n \
    --arg reason "You have ${remaining} of ${total} tasks remaining in the active plan (${plan_name}). Continue working on the next task." \
    --arg msg "Straw: ${remaining} tasks remaining" \
    '{"decision": "block", "reason": $reason, "systemMessage": $msg}'
  exit 0
fi

# All tasks done — check if verification passed
progress_dir=".straw/progress"
if [ -d "$progress_dir" ]; then
  last_progress=$(ls -t "$progress_dir"/*.md 2>/dev/null | head -1)
  if [ -n "$last_progress" ]; then
    verified=$(grep -ci 'verification.*pass' "$last_progress" 2>/dev/null || echo 0)
    if [ "$verified" -eq 0 ]; then
      jq -n \
        --arg reason "All tasks complete but verification has not been confirmed. Run the verification commands before stopping." \
        --arg msg "Straw: run verification" \
        '{"decision": "block", "reason": $reason, "systemMessage": $msg}'
      exit 0
    fi
  fi
fi

# All done and verified — clean up ACTIVE marker and allow stop
rm -f "$active_file"
exit 0
