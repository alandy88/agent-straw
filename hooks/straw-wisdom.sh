#!/usr/bin/env bash
# straw-wisdom.sh — PostToolUse hook for Agent tool
# Captures sub-agent result summaries to a session-scoped wisdom file.
# Reads tool result JSON from stdin, appends summary to temp file.
# Always exits 0 — never blocks.
set -uo pipefail
trap 'exit 0' ERR

# Read tool result JSON from stdin
input=$(cat)

# Extract tool name — only process Agent tool results
tool_name=$(echo "$input" | jq -r '.tool_name // empty' 2>/dev/null)
if [ "$tool_name" != "Agent" ]; then
  exit 0
fi

# Extract agent type and output
agent_type=$(echo "$input" | jq -r '.tool_input.subagent_type // "unknown"' 2>/dev/null)
tool_output=$(echo "$input" | jq -r '.tool_output // empty' 2>/dev/null)

# Skip if no output
if [ -z "$tool_output" ]; then
  exit 0
fi

# Take last 200 chars as summary (agent results are already concise)
summary=$(echo "$tool_output" | tail -c 200 | tr '\n' ' ')

# Session ID: use CLAUDE_CODE_SESSION_ID if available
session_id="${CLAUDE_CODE_SESSION_ID:-unknown}"
wisdom_file="${TMPDIR:-/tmp}/straw-wisdom-${session_id}.txt"

# Append timestamped entry
echo "[$(date '+%H:%M:%S')] [${agent_type}] ${summary}" >> "$wisdom_file"

exit 0
