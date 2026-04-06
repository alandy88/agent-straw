# agent-straw

A Claude Code plugin that provides an orchestrator agent with automatic intent classification, model routing, and autonomous execution loops.

## Install

```bash
claude plugin add github:peteryu/agent-straw
```

## Usage

### Interactive (daily driver)

```bash
claude --agent straw
```

Straw auto-classifies your messages and routes to the optimal agent/model:

```
[straw:implement → sonnet] Adding validation to the form handler
[straw:plan → opus] Delegating to straw-prometheus for planning
[straw:quick → haiku] Looking up that file for you
```

### In-Session Loop

Inside a Claude session:

```
/straw-loop --plan .straw/plans/feature.md --max-iterations 15
```

Uses the Stop hook to keep the agent working until the plan is complete.

### External Ralph Loop (fire and forget)

From your terminal:

```bash
./scripts/straw-loop.sh --plan .straw/plans/feature.md --verify "npm test" --max 20
```

Each iteration gets a fresh context window. Progress is tracked in `.straw/progress/`.

## Agent Hierarchy

| Agent | Model | Role |
|---|---|---|
| **straw** | opus | Orchestrator — classifies intent, routes to sub-agents |
| **straw-prometheus** | opus | Planner — interviews, explores codebase, writes plans |
| **straw-metis** | opus | Plan reviewer — finds gaps, ambiguity, scope creep |
| **straw-atlas** | sonnet | Conductor — executes plans by delegating to Junior |
| **straw-junior** | sonnet* | Executor — writes code, runs tests, commits (*model set by caller) |
| **straw-oracle** | opus | Consultant — read-only advisor for architecture/debugging |

## Hooks

- **straw-wisdom.sh** (PostToolUse) — Captures sub-agent learnings to session-scoped temp file
- **straw-continuation.sh** (Stop) — Prevents exit when plan has incomplete tasks

## Project Files

Straw creates a `.straw/` directory in your project:

```
.straw/
├── plans/        # Plan files and ACTIVE marker
└── progress/     # Per-session progress logs
```

Add `.straw/` to your `.gitignore`.

## License

MIT
