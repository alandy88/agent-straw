# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

agent-straw is a Claude Code plugin that provides an orchestrator agent (`straw`) with automatic intent classification, model routing, a six-agent hierarchy, and autonomous execution loops. It is installed via `claude plugin add` and consumed by Claude Code — there is no build step, test suite, or runtime beyond the Claude Code CLI itself.

## Plugin Structure

```
.claude-plugin/plugin.json  — Plugin manifest with marketplace metadata
agents/                     — Agent definitions (markdown with YAML frontmatter)
commands/                   — Slash commands (/straw-loop, /straw-cancel)
hooks/                      — Shell hooks + hooks.json manifest
scripts/                    — CLI scripts for external loop mode
```

## Agent Hierarchy

Straw (opus) is the entry point. It classifies every user message into a category (`quick`, `implement`, `plan`, `research`, `review`, `autonomous`) and delegates:

- **lukcid** (opus) — planner; writes plans to `.straw/plans/`; read-only on source code
- **maebari** (opus) — plan reviewer, rich with resources; returns APPROVE or REVISE; strictly read-only
- **ceui** (sonnet) — grinder; executes approved plans by delegating tasks to Zansin; never writes source code directly
- **zansin** (sonnet) — invoker; the only agent that writes source code; has no Agent tool so it cannot delegate
- **kong** (opus) — thinker and guide; read-only consultant; has only Read/Grep/Glob tools

Key constraint: agents higher in the hierarchy never write source code. Only Zansin writes code.

## Two Loop Modes

**In-session loop** (`/straw-loop`): The `setup-straw-loop.sh` script creates a `.straw/plans/ACTIVE` marker and progress file. The Stop hook (`straw-continuation.sh`) blocks session exit while tasks remain incomplete, keeping the agent working within a single context window.

**External loop** (`scripts/straw-loop.sh`): Runs `claude -p` in a bash loop. Each iteration gets a fresh context window. The plan file's `- [ ]`/`- [x]` checkboxes track progress across iterations.

Both modes use the same plan format (markdown with checkbox tasks) and the same completion signal: `<promise>COMPLETE</promise>`.

## Hooks

Defined in `hooks/hooks.json`:

- **straw-wisdom.sh** (PostToolUse on Agent) — appends sub-agent result summaries to `$TMPDIR/straw-wisdom-{session}.txt` so Ceui can pass learnings forward
- **straw-continuation.sh** (Stop) — reads `.straw/plans/ACTIVE`, counts incomplete checkboxes, blocks exit if tasks remain or verification hasn't passed

## Marketplace Metadata

The `.claude-plugin/plugin.json` manifest includes fields for Claude Code Marketplace discovery:

- **Core**: `name`, `version`, `description`, `license` — required for any plugin
- **Discovery**: `category` (marketplace filtering), `keywords` (search), `homepage`
- **Author**: `name` (and optionally `email` for support contact)
- **Source**: `repository` — used by `claude plugin add github:{owner}/{repo}`

When adding new metadata fields, reference the official schema at [Claude Code plugin marketplace docs](https://code.claude.com/docs/en/plugin-marketplaces). The `category` must be one of the official values (e.g., `productivity`, `development`, `security`, `testing`).

## Development Notes

- No build/lint/test commands — this is a collection of markdown agent definitions and shell scripts
- Agent definitions use YAML frontmatter (`name`, `description`, `tools`, `model`) followed by markdown instructions
- The `tools` array in frontmatter controls which Claude Code tools each agent can access — this is the primary security boundary (e.g., Zansin has no `Agent` tool, Kong has no `Edit`/`Write`/`Bash`)
- Plan files live in `.straw/plans/` with checkbox tasks (`- [ ]`/`- [x]`); the continuation hook parses these with grep
- The `.straw/` directory is gitignored — it contains runtime state, not plugin code
