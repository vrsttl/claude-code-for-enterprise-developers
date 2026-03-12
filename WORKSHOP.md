# AI Workshop: Claude Code for Enterprise Engineers

Full-day hands-on workshop for effective AI-assisted development with Claude Code.

---

## Morning: Onboarding (9:00 - 12:30)

### Block 1: Why AI-Assisted Development (9:00 - 9:45)

**The shift**: Not autocomplete - agentic workflows where the main thread orchestrates and agents implement.

**Industry context:**
- **Shopify** (2025): CEO memo made AI "non-optional." Teams prove AI can't do a task before requesting headcount.
- **Stripe** (2026): "Minions" merges 1,300+ autonomous PRs/week. "The tool that wins is the one with the best infrastructure around the model."
- **Stack Overflow 2025**: 65% of devs use AI tools weekly, only 29% fully trust output.

**Live demo**: Solve a real bug from your team's backlog end-to-end in ~5 minutes.

**Key message**: "This doesn't replace you - it changes what you spend time on."

**Pro tip**: Claude Code has a built-in help agent. Ask it anything about its own capabilities:

> "Can Claude Code run tests inside a k8s pod?"

Claude will consult its built-in guide and give you a straight answer. No setup needed.

### Block 2: Foundation - CLAUDE.md, Rules & Core Features (9:45 - 10:30)

- **CLAUDE.md**: Your AI's operating manual
- **Folder management**: Per-ticket directories with breadcrumb CLAUDE.md files
- **Worktrees**: `isolation: "worktree"` on Agent tool
- **Rules**: Modular governance files
- **Ultrathink**: `alwaysThinkingEnabled` - deeper reasoning
- **Plan mode**: `/plan` - think before acting
- **`/loop`**: Recurring automation

**Hands-on**: Everyone installs the repo, verifies CLAUDE.md loads.

### Break (10:30 - 10:45)

### Block 3: Agents - Your Specialist Team (10:45 - 11:30)

- **Concept**: Agents = specialized workers with tools, knowledge, model tier
- **Anatomy**: Walk through `frontend-engineer.md`
- **Delegation pattern**: Main thread reads, agent writes
- **Model tiers**: Opus vs Sonnet vs Haiku

### Block 4: Hooks - Guardrails That Enforce Quality (11:30 - 12:00)

- **What hooks are**: PreToolUse, SubagentStop, SessionStart
- **Delegation enforcement**: Why main thread can't edit code
- **Walk through**: `enforce_delegation.py` line by line
- **Live demo**: Edit blocked → delegate → success

### Block 5: Skills, MCP & Plugin Ecosystem (12:00 - 12:30)

- **Skills**: `/command` workflows
- **TDD skill**: `/tdd` enforces red-green-refactor with test verification gates
- **MCP as plugins**: enabledPlugins in settings.json
- **Live demo**: jira-utility via Atlassian plugin

### Lunch (12:30 - 13:30)

---

## Afternoon: Tiered Challenges (13:30 - 17:00)

### Tier 1: Beginner - "Get Comfortable" (13:30 - 16:00)

Challenges:
1. **Bug fix** from team backlog using appropriate agent
2. **Code review** of recent PR using code-reviewer agent
3. **Plan mode workflow** with ultrathink
4. **Loop + monitor** for CI/deploy

Success: Completed task with 1+ agent + plan mode or /loop.

### Tier 2: Intermediate - "Build Your Agent Team" (13:30 - 16:00)

Challenges:
1. **Create custom agent** for team domain
2. **Agent team coordination** with 2-agent workflow
3. **Build a skill** for repetitive workflow (reference: `/tdd` skill)
4. **MCP integration** with new plugin

Success: Working agent/skill others could use.

### Tier 3: Advanced - "Push the Boundaries" (13:30 - 16:00)

Challenges:
1. **Multi-agent pipeline** coordinating 3+ agents
2. **Domain health automation** (agent + skill + hook)
3. **Cross-repo analysis** via Serena + agents
4. **Custom hook system** for quality gate
5. **Build a `/test-in-cluster` skill** - Create a skill that runs PHPUnit tests inside k8s containers. The challenge: PHPUnit is designed to run inside k8s pods, not locally. Build a skill where a developer can say `/test-in-cluster MyService --filter=testCalculateSalary` and have it just work. This requires:
   - Encoding dev environment knowledge (namespaces, pod selection, kubefwd setup)
   - Giving Claude the tools to discover pods and execute commands in containers
   - Handling the kubefwd dependency (port-forwarding k8s services to localhost)
   - Abstracting away the infrastructure so the skill user doesn't think about k8s

Success: Working demo with clear team value.

### Showcase & Wrap-up (16:00 - 17:00)

- 3-5 min volunteer demos
- Discussion: surprises, Monday plans
- Share repo + instructions
- Q&A + feedback collection

---

## Quick Reference

### Essential Commands

| Command | What it does |
|---------|-------------|
| `/plan` | Enter plan mode |
| `/loop 5m check build` | Recurring command every 5 min |
| `/commit` | Guided git commit |
| `/review-pr 123` | Review a PR |
| `/tdd` | TDD red-green-refactor cycle |
| `/clear` | Clear context |

### Talking to Claude

You don't need special syntax. Just describe what you want:

> "Fix the search filter bug in web-app that returns 0 results for special characters"
>
> "Review PR #456 in api-gateway - focus on security and backward compatibility"
>
> "What's the status of PROJ-789?"

Claude delegates to the right specialist agent automatically.

### Key Repo Paths

| App | Path |
|-----|------|
| api-gateway | ~/company/src/api-gateway/ |
| web-app | ~/company/src/web-app/ |
| user-service | ~/company/src/user-service/ |
| billing-service | ~/company/src/billing-service/ |
| admin-portal | ~/company/src/admin-portal/ |
| ui-library | ~/company/src/ui-library/ |

---

## Facilitator Notes

- Verify all attendees have CC installed and licensed
- Test sync-to-claude.sh on fresh machine
- Identify 3-4 TAs (early adopters)
- Set up Slack channel for Q&A
- Pre-record 2-3 backup demo videos
- Prepare demo scenarios for each morning block
