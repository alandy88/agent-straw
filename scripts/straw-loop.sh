#!/usr/bin/env bash
# straw-loop.sh — External Ralph Loop for Straw orchestrator
# Runs claude -p in a bash loop, one task per iteration, fresh context each time.
#
# Usage:
#   straw-loop --plan path/to/plan.md [--verify "cmd"] [--max 20] [--agent straw]
set -euo pipefail

MAX_ITERATIONS=20
VERIFY_CMD=""
AGENT="straw"
PLAN_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan)    PLAN_FILE="$2"; shift 2 ;;
    --verify)  VERIFY_CMD="$2"; shift 2 ;;
    --max)     MAX_ITERATIONS="$2"; shift 2 ;;
    --agent)   AGENT="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: straw-loop --plan <file> [--verify <cmd>] [--max <n>] [--agent <name>]"
      echo ""
      echo "External Ralph Loop — runs claude -p in a bash loop with fresh context per iteration."
      echo ""
      echo "Options:"
      echo "  --plan     Path to the plan file (required)"
      echo "  --verify   Verification command run after each iteration"
      echo "  --max      Maximum iterations (default: 20)"
      echo "  --agent    Agent to use (default: straw)"
      echo ""
      echo "Examples:"
      echo "  straw-loop --plan .straw/plans/feature.md --verify 'npm test' --max 15"
      echo "  straw-loop --plan .straw/plans/bugfix.md --max 5"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [ -z "$PLAN_FILE" ]; then
  echo "Error: --plan is required"
  exit 1
fi

if [ ! -f "$PLAN_FILE" ]; then
  echo "Error: Plan file not found: $PLAN_FILE"
  exit 1
fi

# Create progress file
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
PROGRESS_DIR=".straw/progress"
mkdir -p "$PROGRESS_DIR"
PROGRESS_FILE="${PROGRESS_DIR}/${TIMESTAMP}.md"

PLAN_NAME=$(grep -m1 '^# ' "$PLAN_FILE" | sed 's/^# //' || echo "Unnamed Plan")
echo "# Progress: ${PLAN_NAME}" > "$PROGRESS_FILE"
echo "Started: $(date '+%Y-%m-%d %H:%M:%S')" >> "$PROGRESS_FILE"
echo "" >> "$PROGRESS_FILE"

echo "=== Straw Loop (External) ==="
echo "Plan:       $PLAN_FILE"
echo "Progress:   $PROGRESS_FILE"
echo "Agent:      $AGENT"
echo "Max:        $MAX_ITERATIONS iterations"
echo "Verify:     ${VERIFY_CMD:-none}"
echo "============================="
echo ""

START_TIME=$(date +%s)

for ((i=1; i<=MAX_ITERATIONS; i++)); do
  ITER_START=$(date +%s)
  echo "--- Iteration $i of $MAX_ITERATIONS ---"

  TOTAL=$(grep -cE '^\s*- \[(x| )\]' "$PLAN_FILE" 2>/dev/null || echo 0)
  COMPLETED=$(grep -cE '^\s*- \[x\]' "$PLAN_FILE" 2>/dev/null || echo 0)
  echo "Tasks: $COMPLETED/$TOTAL complete"

  RESULT=$(claude -p --agent "$AGENT" \
    "@${PLAN_FILE}" \
    "@${PROGRESS_FILE}" \
    "You are in Straw Loop mode (iteration $i of $MAX_ITERATIONS).
Pick the next incomplete task from the plan. Execute it. Update the progress file. Commit your changes.
ONLY WORK ON A SINGLE TASK per iteration.
If ALL tasks are complete and verification passes, output <promise>COMPLETE</promise>.
If tasks remain, just exit after completing the one task." 2>&1) || true

  ITER_END=$(date +%s)
  ITER_ELAPSED=$((ITER_END - ITER_START))
  echo "Iteration took ${ITER_ELAPSED}s"

  if echo "$RESULT" | grep -q '<promise>COMPLETE</promise>'; then
    echo ""
    echo "Agent signals completion."

    if [ -n "$VERIFY_CMD" ]; then
      echo "Running verification: $VERIFY_CMD"
      if eval "$VERIFY_CMD"; then
        TOTAL_ELAPSED=$(( $(date +%s) - START_TIME ))
        echo ""
        echo "=== COMPLETE ==="
        echo "All tasks done. Verification passed."
        echo "Iterations: $i"
        echo "Total time: ${TOTAL_ELAPSED}s"
        exit 0
      else
        echo "Verification FAILED. Continuing..."
        echo "VERIFICATION FAILED at iteration $i" >> "$PROGRESS_FILE"
      fi
    else
      TOTAL_ELAPSED=$(( $(date +%s) - START_TIME ))
      echo ""
      echo "=== COMPLETE ==="
      echo "All tasks done (no verification command configured)."
      echo "Iterations: $i"
      echo "Total time: ${TOTAL_ELAPSED}s"
      exit 0
    fi
  fi

  if [ -n "$VERIFY_CMD" ]; then
    echo "Running verification: $VERIFY_CMD"
    if ! eval "$VERIFY_CMD" 2>&1; then
      echo "" >> "$PROGRESS_FILE"
      echo "## Verification Failure (Iteration $i)" >> "$PROGRESS_FILE"
      echo "Command: \`${VERIFY_CMD}\`" >> "$PROGRESS_FILE"
      echo "Status: FAILED" >> "$PROGRESS_FILE"
    fi
  fi

  echo ""
done

TOTAL_ELAPSED=$(( $(date +%s) - START_TIME ))
COMPLETED=$(grep -cE '^\s*- \[x\]' "$PLAN_FILE" 2>/dev/null || echo 0)
TOTAL=$(grep -cE '^\s*- \[(x| )\]' "$PLAN_FILE" 2>/dev/null || echo 0)

echo "=== MAX ITERATIONS REACHED ==="
echo "Completed $COMPLETED of $TOTAL tasks in $MAX_ITERATIONS iterations."
echo "Total time: ${TOTAL_ELAPSED}s"
echo "Review progress: $PROGRESS_FILE"
exit 1
