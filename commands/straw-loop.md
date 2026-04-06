---
description: "Start a Straw autonomous loop on a plan file"
argument-hint: "--plan <file> [--max-iterations N] [--completion-promise TEXT]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-straw-loop.sh:*)"]
---

# Straw Loop Command

Execute the setup script to initialize the Straw loop:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-straw-loop.sh" $ARGUMENTS
```

You are now in Straw Loop mode. Work through the plan task by task. The Stop hook will keep you going until all tasks are complete and verification passes.

CRITICAL RULE: You may ONLY output `<promise>COMPLETE</promise>` (or your custom promise) when ALL tasks are genuinely done and ALL verification commands pass. Do not output a false promise to escape the loop.
