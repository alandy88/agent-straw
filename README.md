# agent-straw

A Claude Code plugin with a six-agent hierarchy for automatic intent classification, model routing, and autonomous plan execution.

## Install

```bash
claude plugin add github:alandy88/agent-straw
```

## Usage

### Interactive (daily driver)

```bash
claude --agent straw
```

Straw auto-classifies your messages and routes to the optimal agent/model:

```
[straw:implement → sonnet] Adding validation to the form handler
[straw:plan → opus] Delegating to lukcid for planning
[straw:quick → haiku] Looking up that file for you
```

### In-Session Loop

Inside a Claude session:

```
/straw-loop --plan .straw/plans/feature.md --max-iterations 15
```

The Stop hook keeps the agent working until all plan tasks are complete.

### External Loop (fire and forget)

From your terminal:

```bash
./scripts/straw-loop.sh --plan .straw/plans/feature.md --verify "npm test" --max 20
```

Each iteration gets a fresh context window. Progress is tracked in `.straw/progress/`.

## Agents

| Agent | Model | Role |
|---|---|---|
| **straw** | opus | Orchestrator — classifies intent, routes to sub-agents |
| **lukcid** | opus | Planner — explores codebase, writes plans to `.straw/plans/` |
| **maebari** | opus | Reviewer — validates plans for gaps, ambiguity, scope creep |
| **ceui** | sonnet | Grinder — executes plans task-by-task, delegates to zansin |
| **zansin** | sonnet* | Invoker — writes code, runs tests, commits (*model set by caller) |
| **kong** | opus | Thinker & guide — read-only advisor for architecture and debugging |

### Task Flows

**Simple task** (single-file change):
`straw → zansin`

**Complex feature** (multi-step plan):
`straw → lukcid → maebari → (APPROVE) → ceui → zansin`

**Research / advice**:
`straw → kong`

Only zansin writes source code. All other agents are read-only on source or delegate downward.

## Hooks

- **straw-wisdom.sh** (PostToolUse) — captures sub-agent learnings to a session-scoped temp file
- **straw-continuation.sh** (Stop) — blocks exit when an active plan has incomplete tasks

## Runtime Files

Straw creates a `.straw/` directory in your project at runtime:

```
.straw/
├── plans/        # Plan files and ACTIVE marker
└── progress/     # Per-session progress logs
```

Add `.straw/` to your `.gitignore`.

## License

MIT
