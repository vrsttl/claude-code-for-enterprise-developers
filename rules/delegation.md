# Agent Delegation Rules

## Decision Flow

```
1. Simple query (no implementation)? → Answer directly
2. Single-agent task? → Direct invoke using matrix below
3. Multi-agent task (multiple technologies)? → Parallel agent invocation
```

## Agent Selection Matrix

| Pattern in Prompt | Technology | Agent |
|-------------------|------------|-------|
| PHP/Symfony/Laravel/Doctrine API | PHP backend | staff-php-developer |
| React/Next.js/Vue/TypeScript | Frontend | frontend-engineer |
| JIRA ticket ID (XXX-###) | Jira | jira-utility |
| Research/documentation | Web | web-researcher |
| Code review/quality | Review | code-reviewer |

## Mandatory Delegation Rules

**Main thread MUST NOT edit code directly.** All code modifications must be delegated to the appropriate agent.

| File Type / Technology | Required Agent | Never Use |
|------------------------|---------------|-----------|
| React/TypeScript/JSX/CSS | frontend-engineer | Direct Edit, Serena edit tools |
| PHP/Symfony/Laravel | staff-php-developer | Direct Edit, Serena edit tools |
| Test files (.spec/.test) | Same agent as source file | Direct Edit, Serena edit tools |

### Serena MCP Tools

**READ-ONLY on main thread (allowed):**
- `read_file`, `find_symbol`, `find_referencing_symbols`, `get_symbols_overview`
- `search_for_pattern`, `list_dir`, `find_file`
- `list_memories`, `read_memory`, `check_onboarding_performed`
- `activate_project`, `write_memory`, `edit_memory`, `delete_memory`

**BLOCKED on main thread (must delegate):**
- `replace_content`, `replace_symbol_body`, `create_text_file`
- `insert_after_symbol`, `insert_before_symbol`, `rename_symbol`
- `delete_lines`, `insert_at_line`, `replace_lines`
- `execute_shell_command` (delegate to agents for any shell execution)

### Enforcement
These rules are enforced by the PreToolUse hook. Violations will be blocked with a delegation suggestion.

## Invocation Format

```
Agent("agent-name", "detailed task description with context")
```

Never use Python imports for agents. Always use Agent tool.

## Repo Discovery Protocol

All repos live at `~/company/src/{repo-name}/`.

**Primary: Serena MCP** - project names match repo folder names:
```
activate_project('{repo-name}')
```

**Rules:**
- Main thread MUST include the full repo path in every agent prompt
- Template: `Repository: ~/company/src/{repo-name}/ (Serena project: {repo-name})`
- If target repo is unclear, ask user before delegating
- Agents must NEVER create source files under `~/agentic-working/`
