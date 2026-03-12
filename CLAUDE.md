# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A starter kit that syncs Claude Code configuration (agents, rules, hooks, skills, plugins) to `~/.claude/`. Not an application, there is no build/test/lint. The primary artifact is the configuration files themselves.

## Install / Sync

```bash
./sync-to-claude.sh          # macOS/Linux (backs up existing config first)
.\sync-to-claude.ps1         # Windows PowerShell
```

Options: `--backup-only`, `--no-backup`, `--list-backups`

Syncs to `~/.claude/`: `CLAUDE_GLOBAL.md` becomes `~/.claude/CLAUDE.md`, plus `agents/`, `rules/`, `hooks/`, `skills/`, `examples/`, `settings.json`.

## Core Design Pattern

**Main thread coordinates, agents implement.** The orchestrator never edits code directly. Three hooks enforce this:

1. `enforce_delegation.py` (PreToolUse) - Blocks Edit/Write/Bash/Serena mutations on main thread using a semaphore file (`.claude/.in_subtask.flag`)
2. `pretask_flag.py` (PreToolUse on Agent/Task) - Validates agent names against `~/.claude/agents/*.md` allowlist, enforces model tiers from frontmatter, increments the semaphore counter
3. `agent_stop.py` (SubagentStop) - Decrements the counter, deletes flag when all agents finish

The semaphore uses file locking (`fcntl.flock`) for safe concurrent agent execution.

## Agents (7)

| Agent | Model | Domain |
|-------|-------|--------|
| frontend-engineer | Opus | React, TypeScript, Next.js |
| staff-php-developer | Opus | PHP 8.x, Symfony, Laravel |
| code-reviewer | Opus | Read-only analysis and review |
| devops-engineer | Opus | CI/CD, Docker/K8s, IaC, shell/git ops |
| jira-utility | Haiku | Jira CRUD via Atlassian MCP |
| web-researcher | Sonnet | Web research, documentation |
| agent-creator | Sonnet | Creates new agents from templates |

Agent files use YAML frontmatter (`name`, `model`, `description`, `tools`). The `model` field in frontmatter is enforced by `pretask_flag.py`.

## Rules (4 files in `rules/`)

- `delegation.md` - Agent selection matrix, Serena tool permissions (read-only vs blocked on main thread)
- `code-quality.md` - Anti-over-engineering guidelines, verification patterns
- `context-management.md` - Memory system types, CLAUDE.md hierarchy, compaction thresholds
- `mcp-usage.md` - Plugin config, Atlassian Cloud ID placeholder, Serena one-project constraint

## Skills (4)

| Skill | Trigger | What It Does |
|-------|---------|--------------|
| `/commit` | Guided git commit | Analyzes diffs, generates conventional commit message |
| `/review-pr` | PR review | Fetches PR via `gh`, delegates to code-reviewer |
| `/tdd` | TDD workflow | Enforces RED-GREEN-REFACTOR with test verification gates |
| `/create-agent` | Agent creation | Two-phase: intake interview + rules compilation, then delegates to agent-creator |

## Plugins (settings.json)

Serena, Context7, Frontend Design, Skill Creator. Configured via `enabledPlugins`. Also enables `alwaysThinkingEnabled` (ultrathink) and `effortLevel: "high"`.

## Key Files to Edit Together

When modifying the delegation pattern:
- `hooks/enforce_delegation.py` (BLOCKED dict)
- `hooks/pretask_flag.py` (allowlist, model enforcement)
- `hooks/agent_stop.py` (counter cleanup)
- `rules/delegation.md` (selection matrix, Serena tool permissions)
- `CLAUDE_GLOBAL.md` (agent list, model tiers section)

When adding a new agent:
- `agents/{name}.md` (the agent definition)
- `rules/delegation.md` (add to selection matrix)
- `CLAUDE_GLOBAL.md` (add to agent list and model tiers)
- `sync-to-claude.sh` (update expected agent count in `validate_sync` if needed)

## Conventions

- Agent names must match their filename minus `.md` (e.g., `frontend-engineer.md` registers as `frontend-engineer`)
- Hard-blocked subagent types: `Bash`, `general-purpose` (forces named specialists)
- Built-in always-allowed types: `statusline-setup`, `claude-code-guide`, `Plan`, `Explore`
- Repo paths follow `~/company/src/{repo-name}/` convention; Serena project names match folder names
- Per-ticket workspaces: `~/agentic-working/{year}/week-{N}/{TICKET-ID}/CLAUDE.md`
