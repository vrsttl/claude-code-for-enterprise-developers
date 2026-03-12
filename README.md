# Claude Code for Enterprise Developers

Starter kit for using Claude Code effectively in enterprise teams. Includes agents, rules, hooks, skills, and a plugin-first MCP configuration.

## Quick Start

```bash
# Clone the repo
git clone <repo-url> ~/claude-code-enterprise
cd ~/claude-code-enterprise

# Run the installer (backs up existing config first)
./sync-to-claude.sh
```

**Windows (PowerShell):**
```powershell
.\sync-to-claude.ps1
```

This syncs to `~/.claude/`:
- **7 agents** (frontend-engineer, staff-php-developer, code-reviewer, devops-engineer, jira-utility, web-researcher, agent-creator)
- **4 rule files** (delegation, code-quality, context-management, mcp-usage)
- **3 hooks** (enforce delegation, agent validation, agent cleanup)
- **4 skills** (/commit, /review-pr, /tdd, /create-agent)
- **settings.json** (hooks config, plugin list, ultrathink enabled)
- **CLAUDE_GLOBAL.md** → `~/.claude/CLAUDE.md`

## What You Get

### Agents
Specialist workers that Claude delegates to. Main thread reads code, agents write code.

| Agent | Model | Use For |
|-------|-------|---------|
| frontend-engineer | Opus | React, TypeScript, Next.js |
| staff-php-developer | Opus | PHP, Symfony, Laravel |
| code-reviewer | Opus | Code quality, security audits |
| devops-engineer | Opus | CI/CD, Docker/K8s, IaC, shell/git |
| jira-utility | Haiku | Jira ticket operations |
| web-researcher | Sonnet | Web research, documentation |
| agent-creator | Sonnet | Create new agents following established patterns |

### Rules
Governance files that shape Claude's behavior:
- **delegation.md** - Which agent handles what (selection matrix)
- **code-quality.md** - Implementation guidelines (no over-engineering)
- **context-management.md** - Session management, compaction thresholds
- **mcp-usage.md** - Plugin config, Atlassian Cloud ID

### Hooks
Python scripts that enforce quality:
- **enforce_delegation.py** - Blocks Edit/Write/Bash on main thread, forces agent delegation
- **pretask_flag.py** - Validates agent names, enforces model tiers
- **agent_stop.py** - Cleans up when agents finish

### Skills
Reusable workflows triggered by slash commands:
- `/commit` - Guided git commit with conventional message
- `/review-pr` - Structured PR review via code-reviewer agent
- `/tdd` - Test-driven development with red-green-refactor enforcement
- `/create-agent` - Guided agent creation with domain research and rules compilation

### Plugins (MCP)
Configured in settings.json → enabledPlugins:
- **Serena** - Semantic code analysis (LSP-powered) - see [SERENA.md](SERENA.md)
- **Context7** - Real-time library documentation
- **Figma** - Design spec integration
- **Skill Creator** - Build new skills

## Plugin Authentication

Some plugins need auth on first use:

### Atlassian (Jira/Confluence)
1. Open Claude Code
2. The Atlassian plugin prompts for OAuth on first use
3. Log in with your Atlassian credentials
4. Find your Cloud ID: run `gh api` or check your Atlassian admin settings, then update `rules/mcp-usage.md`

### GitHub
Claude Code uses the `gh` CLI directly for all GitHub operations (PRs, issues, repos). No MCP needed.
1. Install: `brew install gh`
2. Authenticate: `gh auth login`
3. Verify: `gh auth status`

## Folder Management

Recommended per-ticket workspace pattern:

```
~/agentic-working/
└── 2026/
    └── week-12/
        └── TICKET-123/
            └── CLAUDE.md    # breadcrumb file (repo ref, scope, key files)
```

The CLAUDE.md chain loads context hierarchically:
1. `~/.claude/CLAUDE.md` (global)
2. Project root CLAUDE.md
3. Working directory CLAUDE.md (ticket-specific)

See `examples/ticket-workspace/CLAUDE.md` for a template.

## Quality Controls

See [QUALITY_CONTROLS.md](QUALITY_CONTROLS.md) for the full guide on:
- Writing effective prompts (RICE framework)
- Self-checks and verification patterns
- Review loops (agent, human, CodeRabbit, SonarQube)
- Advanced: Embedding Claude Code bot in your repo via webhooks

## Extending

### Add a new agent
1. Create `~/.claude/agents/your-agent-name.md`
2. Include YAML frontmatter: name, model, description, tools
3. The agent is immediately available

### Add a new skill
1. Create `~/.claude/skills/your-skill/SKILL.md`
2. Define name, description, version in frontmatter
3. Trigger with `/your-skill`

### Add more plugins
Edit `~/.claude/settings.json` → `enabledPlugins`

## Troubleshooting

**"BLOCKED: Edit not allowed on main thread"**
This is the delegation hook working correctly. Just describe what you want changed:

> "Fix the search filter bug in web-app"

Claude will delegate to the appropriate agent automatically.

**Agent not found in allowlist**
Create the agent .md file in `~/.claude/agents/` or check the name.

**Serena not connecting**
Ensure the Serena plugin is enabled in settings.json and restart Claude Code.
Each repo needs one-time onboarding - see [SERENA.md](SERENA.md).

**"Can Claude Code do X?"**
Just ask - Claude has a built-in help guide:

> "Can Claude Code access my browser?"

## Workshop

See [WORKSHOP.md](WORKSHOP.md) for the full-day workshop schedule and challenge descriptions.
