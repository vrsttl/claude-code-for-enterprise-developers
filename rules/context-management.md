# Context & Memory Management Rules

## Memory System

Claude Code has built-in persistent memory. Use it actively.

**Auto memory** (enabled by default):
- Stored at `~/.claude/projects/<project>/memory/`
- `MEMORY.md` index (first 200 lines loaded every session)
- Topic files for detailed knowledge (loaded on demand)
- Claude reads/writes automatically, but explicit prompts help

**When to prompt memory updates:**
- After learning something reusable: "Save this pattern to memory"
- After resolving a tricky bug: "Remember this fix for future sessions"
- After discovering a codebase convention: "Add this to your memory"
- After a user preference is stated: "Remember I prefer X"
- After completing a multi-session task: "Update memory with what we learned"

**When to consult memory:**
- Starting a new session on the same project: "Check your memory for context"
- Before repeating work: "Have we solved something like this before?"
- When uncertain about conventions: "What do your memories say about X?"

**Memory types to save:**
| Type | Example | When |
|------|---------|------|
| user | Role, preferences, expertise level | Learning about the user |
| feedback | "Don't mock the DB in tests" | User corrects approach |
| project | "Merge freeze starts March 5" | Learning project state |
| reference | "Pipeline bugs tracked in Linear INGEST" | External system pointers |

**What NOT to save** (derivable from code/git):
- Code patterns, file paths, architecture (read the code)
- Git history, recent changes (use git log/blame)
- Anything already in CLAUDE.md files

## CLAUDE.md Files

The persistent instruction layer. Survives compaction (re-injected fresh).

| Level | Location | Loaded |
|-------|----------|--------|
| Org/Managed | `/Library/Application Support/ClaudeCode/CLAUDE.md` | Always (highest priority) |
| User | `~/.claude/CLAUDE.md` | Always |
| Project | `<repo>/.claude/CLAUDE.md` or `<repo>/CLAUDE.md` | Always |
| Directory | `<subdir>/CLAUDE.md` | When working in that dir |

**Keep under 200 lines.** Longer files reduce adherence. Use `.claude/rules/` for modular overflow.

## Context Window

**Built-in auto-compaction** triggers at ~95% capacity. Configurable:
```bash
CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=80  # Lower threshold if needed
```

**Commands:**
| Command | Purpose |
|---------|---------|
| `/context` | Check current usage |
| `/compact` | Manual compaction |
| `/compact focus on X` | Compaction preserving topic X |
| `/memory` | View/edit memory files, toggle auto memory |
| `/clear` | Fresh session (memory persists) |

## Best Practices

**Session management:**
- One concern per session (don't mix unrelated tasks)
- Delegate to subagents for large tasks (separate context windows)
- Use `/compact focus on X` before hitting capacity, not after
- Start new sessions freely - memory carries knowledge forward

**Context efficiency:**
- Don't `@`-mention large files (bloats context) - let Claude read them via tools
- Subagent work stays in subagent context (doesn't consume main thread)
- Skills load on-demand (not always in context)
- Check `/mcp` for per-server context costs

**Disable auto memory** (if needed):
```json
{ "autoMemoryEnabled": false }
```
Or: `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`

## Anti-Patterns

- Manually archiving context (built-in compaction handles this)
- Custom compaction scripts (redundant with `/compact`)
- One endless session for everything (use memory + fresh sessions instead)
- Never prompting memory saves (auto memory catches some, but explicit saves are more reliable)
- Storing ephemeral task state in memory (use tasks/plans for current-session tracking)
