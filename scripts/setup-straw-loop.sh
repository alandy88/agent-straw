#!/usr/bin/env bash
# setup-straw-loop.sh — Creates state file for in-session Straw loop
set -euo pipefail

# Parse arguments
PLAN_FILE=""
MAX_ITERATIONS=0
COMPLETION_PROMISE="COMPLETE"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      cat << 'HELP_EOF'
Straw Loop - In-session autonomous loop

USAGE:
  /straw-loop --plan <file> [--max-iterations N] [--completion-promise TEXT]

OPTIONS:
  --plan <file>                  Path to the plan file (required)
  --max-iterations <n>           Max iterations before auto-stop (default: unlimited)
  --completion-promise '<text>'  Promise phrase (default: COMPLETE)
  -h, --help                     Show this help

EXAMPLES:
  /straw-loop --plan .straw/plans/auth-redesign.md
  /straw-loop --plan .straw/plans/fix-bugs.md --max-iterations 10
  /straw-loop --plan .straw/plans/feature.md --completion-promise 'ALL TESTS PASS'
HELP_EOF
      exit 0
      ;;
    --plan)           PLAN_FILE="$2"; shift 2 ;;
    --max-iterations) MAX_ITERATIONS="$2"; shift 2 ;;
    --completion-promise) COMPLETION_PROMISE="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$PLAN_FILE" ]; then
  echo "Error: --plan is required" >&2
  echo "Usage: /straw-loop --plan <file> [--max-iterations N]" >&2
  exit 1
fi

if [ ! -f "$PLAN_FILE" ]; then
  echo "Error: Plan file not found: $PLAN_FILE" >&2
  exit 1
fi

# Create progress file
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
mkdir -p .straw/progress
PROGRESS_FILE=".straw/progress/${TIMESTAMP}.md"
PLAN_NAME=$(grep -m1 '^# ' "$PLAN_FILE" | sed 's/^# //' || echo "Unnamed Plan")
echo "# Progress: ${PLAN_NAME}" > "$PROGRESS_FILE"
echo "Started: $(date '+%Y-%m-%d %H:%M:%S')" >> "$PROGRESS_FILE"
echo "" >> "$PROGRESS_FILE"

# Create ACTIVE marker with session info
mkdir -p .straw/plans
PLAN_BASENAME=$(basename "$PLAN_FILE")
jq -n \
  --arg plan "$PLAN_BASENAME" \
  --arg session "${CLAUDE_CODE_SESSION_ID:-}" \
  --arg progress "$PROGRESS_FILE" \
  '{"plan": $plan, "session_id": $session, "progress": $progress}' \
  > .straw/plans/ACTIVE

# Count tasks
TOTAL=$(grep -cE '^\s*- \[(x| )\]' "$PLAN_FILE" 2>/dev/null || echo 0)

cat <<EOF
Straw Loop activated!

Plan:       $PLAN_FILE ($TOTAL tasks)
Progress:   $PROGRESS_FILE
Max:        $(if [ "$MAX_ITERATIONS" -gt 0 ]; then echo "$MAX_ITERATIONS iterations"; else echo "unlimited"; fi)
Promise:    <promise>$COMPLETION_PROMISE</promise>

The continuation hook will prevent exit until all tasks are complete.
Work on the plan now. The hook will keep you going.

---

@${PLAN_FILE}
@${PROGRESS_FILE}

Pick the next incomplete task from the plan. Execute it. Update the progress file. Commit.
ONLY WORK ON A SINGLE TASK, then try to exit. The loop hook will feed you back if tasks remain.
If ALL tasks are complete and verification passes, output <promise>${COMPLETION_PROMISE}</promise>.
EOF
