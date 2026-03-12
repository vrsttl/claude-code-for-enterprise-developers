# Quality Controls for AI-Assisted Development

How to get reliable, production-grade output from Claude Code. Quality isn't magic - it comes from good inputs, structured verification, and layered review.

---

## 1. Good Prompt Input

The single biggest factor in output quality. Garbage in, garbage out.

### What makes a good prompt

| Element | Bad | Good |
|---------|-----|------|
| Context | "Fix the bug" | "Fix the search filter in web-app that returns 0 results when special characters are in the query. Repo: ~/company/src/web-app/" |
| Scope | "Refactor everything" | "Extract the price calculation logic from OrderService into a PriceCalculator class" |
| Constraints | (none) | "Must maintain backward compatibility with the existing API contract" |
| Acceptance | (none) | "Tests pass, no TypeScript errors, handles empty input gracefully" |

### The RICE framework for prompts

- **Repo**: Always include the repository path and Serena project name
- **Intent**: What you want to achieve (not how)
- **Constraints**: What must NOT change, performance requirements, compatibility
- **Evidence**: How to verify success (test commands, expected output)

### Agent prompts

When delegating to agents, include:
- Repository path: `~/company/src/{repo-name}/` (Serena project: `{repo-name}`)
- Specific file or module scope
- Test command to run after changes
- Any code style or pattern to follow from existing code

---

## 2. Rules as Guardrails

Good prompts get good results once. Rules get good results every time.

The most effective way to make agent output consistent and compliant is to codify your standards into documents the agent reads on every run. Think of it like configuring a linter - you define the rules once, and every execution is checked against them. The difference: these rules can encode architectural decisions, business constraints, and team conventions that no linter can express.

### Why this matters

Without rules, every prompt needs to re-explain your conventions. With rules, the agent inherits your team's standards automatically. The same rule file that tells one developer's agent to use Zod for validation tells every developer's agent the same thing. This is how you get reproducible output across a team.

### Where rules live

| Level | Location | Scope | Example |
|-------|----------|-------|---------|
| Personal | `~/.claude/rules/*.md` | Your machine only | "I prefer functional components over class components" |
| Project | `<repo-root>/.claude/rules/*.md` | Everyone on the repo | "Use Zod for request validation, Doctrine for ORM" |
| Team | Confluence / shared docs | Referenced by project rules | "All API responses follow our envelope format" |
| Org | CLAUDE.md in repo root | Loaded automatically | "No direct DB queries from controllers" |

### What to put in rules

Rules work best when they capture decisions that are already made - things the team has agreed on that shouldn't be re-debated on every PR.

**Good rule content:**
- Architectural patterns: "Services call repositories, never the DB directly"
- Naming conventions: "Events are past tense (`UserRegistered`), commands are imperative (`RegisterUser`)"
- Tech stack constraints: "Use your team's HTTP client wrapper for all API calls (handles auth tokens)"
- Testing standards: "Integration tests hit real DB, no mocked repositories"
- Security boundaries: "PII fields must use the `Encrypted` Doctrine type"

**Bad rule content:**
- Implementation details that change often (specific versions, exact file paths)
- Things already enforced by linters or CI (formatting, import order)
- Opinions without team consensus

### The investment payoff

Writing good rules is front-loaded work. A team that spends a day defining their rules file gets:
- New team members (human or AI) productive faster
- Fewer "we don't do it that way" PR comments
- Agents that produce code matching your standards on the first try
- A living, versionable record of architectural decisions

The goal: define the rules once, enforce them on every run. When the agent follows the same ruleset every time, you get predictable, reviewable output regardless of who wrote the prompt.

### Example: project rules file

```markdown
# .claude/rules/backend.md

## API patterns
- All endpoints return envelope format: { data, meta, errors }
- Use Zod schemas for request validation
- Service layer handles business logic, controllers are thin

## Database
- Doctrine ORM for all queries (no raw SQL in services)
- Migrations must be reversible
- Soft deletes for user-facing entities

## Testing
- PHPUnit for unit tests, no mocked repositories in integration tests
- Minimum: happy path + one error case per public method
```

---

## 3. Permissions and Isolation

Claude Code has a layered permission system. Understanding it is the difference between a useful assistant and a liability.

### The permission model

Every tool call goes through a permission check. When Claude wants to run a command, edit a file, or call an MCP tool, you can:

- **Allow once** - approve this specific invocation
- **Allow always** - approve this tool for the rest of the session
- **Deny** - block this invocation

This is your runtime safety net. But relying on manual approval for every action doesn't scale. The real power is in configuring permissions upfront.

### CLI flags you should know

| Flag | What it does | When to use |
|------|-------------|-------------|
| `--allowedTools` | Whitelist specific tools for the session | Restricting an agent to read-only operations |
| `--disallowedTools` | Blacklist specific tools | Preventing Write/Bash in sensitive contexts |
| `--dangerously-skip-permissions` | Auto-approve everything | **Never in production repos.** Only for sandboxed experiments |

`--dangerously-skip-permissions` does what the name says. It skips all permission checks. Useful for throwaway experiments in isolated environments. Dangerous anywhere else. If you're tempted to use it on a real repo, you probably need better rules or hooks instead.

### Worktrees: isolated agent environments

When you want an agent to work in isolation, tell Claude:

> "Fix the search filter in web-app, use a worktree so it doesn't touch my branch"

Claude creates a `git worktree` - the agent works on a separate branch in a separate directory. If it makes a mess, your working tree is untouched.

Use worktrees when:
- The agent is doing exploratory or risky work
- Multiple agents need to work on the same repo simultaneously
- You want to review changes before they touch your branch

### Resuming work with --continue

```bash
claude --continue
```

Picks up where the last session left off - same context, same permissions, same state. Useful for long-running tasks split across sessions. The agent resumes with full memory of what it was doing.

### Per-agent tool restrictions

Agents don't need access to everything. A code-reviewer shouldn't write files. A jira-utility shouldn't execute shell commands. Restrict tools per agent using the `allowedTools` field in agent definitions or via hooks.

Our setup enforces this through `enforce_delegation.py`:

| Agent | Allowed | Blocked |
|-------|---------|---------|
| code-reviewer | Read, Grep, Glob, Serena read tools | Edit, Write, Bash |
| jira-utility | Atlassian MCP tools | Edit, Write, Bash, Serena |
| frontend-engineer | All tools | (full access - it needs to write code) |
| Main thread | Read, Grep, Glob, Agent | Edit, Write, Bash (must delegate) |

### Hooks as security enforcement

Hooks run on every tool invocation. They can block, modify, or log any action before it executes. This is where you encode hard security boundaries.

**PreToolUse hooks** fire before a tool runs:
```python
# Block destructive git operations
if tool == "Bash" and any(cmd in input for cmd in ["git push --force", "git reset --hard"]):
    print("BLOCKED: Destructive git operation requires manual execution")
    sys.exit(1)
```

**What to enforce in hooks:**
- Block main thread from editing code (force delegation)
- Validate agent names against an allowlist
- Prevent writes to sensitive paths (`.env`, `credentials.json`, CI configs)
- Log all Bash commands for audit
- Block `--force` flags on destructive operations

### The principle of least privilege

The same principle from infrastructure security applies here:

> Don't let an agent work directly in an environment where it can do a lot of harm.

Practical application:
- **Read-only by default**: Agents start with read access. Grant write access only when the task requires it.
- **Scope to the task**: An agent fixing a search filter doesn't need access to the auth module.
- **Isolate risky work**: Use worktrees for changes that touch shared infrastructure.
- **Never auto-merge**: Agent PRs always go through human review, regardless of test results.
- **Sandbox experiments**: Use `--dangerously-skip-permissions` only in disposable environments, never on repos with production code or secrets.

### Quick reference: permission escalation ladder

```
Most restrictive                          Least restrictive
     |                                          |
     v                                          v

  Read-only    ->  Tool whitelist  ->  Full access   ->  Skip permissions
  agent             per agent          with hooks        (sandbox only)
  (reviewer)       (jira-utility)     (engineer)        (experiments)
```

Each step right gives more power and requires more trust. Most agents should live on the left side of this spectrum.

---

## 4. Self-Checks (Built into the Workflow)

Claude Code can verify its own work. This alone improves quality 2-3x.

### Verification patterns

| Check | When | How |
|-------|------|-----|
| Type checking | After any TS/JS change | `npx tsc --noEmit` |
| Linting | After any code change | `npm run lint` or `./vendor/bin/phpcs` |
| Unit tests | After implementation | `npm test` or `./vendor/bin/phpunit` |
| Build | Before declaring done | `npm run build` |

### Encoding verification in prompts

Tell Claude what checks to run after making changes:

> "Fix the search filter bug in web-app. After fixing, run the type checker, the SearchFilter tests, and a full build. Report pass/fail for each."

Claude delegates to the right agent and includes the verification steps automatically.

### The /tdd skill

The TDD skill (`/tdd`) enforces structured red-green-refactor cycles:
1. **RED** - Write failing tests first (verified to fail)
2. **GREEN** - Minimal implementation (verified to pass)
3. **REFACTOR** - Clean up (verified tests still pass)

Each phase boundary requires test execution. See `skills/tdd/SKILL.md`.

---

## 5. Review Loops

Multiple layers of review catch different classes of issues.

### Layer 1: Agent self-review

Ask Claude to review changes before committing:

> "Review my changes in api-gateway on the current branch. Focus on security, performance, and backward compatibility."

Claude delegates to the code-reviewer agent, which analyzes the diff and reports findings.

### Layer 2: Human review

AI-generated code needs human review, especially for:
- Business logic correctness (AI doesn't know your domain as well as you)
- Architectural fit (does this belong here?)
- Edge cases specific to your system
- Data handling and privacy implications

**Rule of thumb**: Review AI output with the same rigor you'd review a junior developer's PR.

### Layer 3: Automated review systems

#### CodeRabbit

AI-powered PR reviewer that runs automatically on every PR.

- Provides line-by-line review comments
- Catches common issues: security, performance, style
- Integrates with GitHub PR workflow
- Learns from your codebase patterns over time

Configuration lives in `.coderabbit.yaml` at repo root. Key settings:
- Review language and tone
- Which file patterns to include/exclude
- Custom review instructions per path

#### SonarQube

Static analysis for code quality and security.

- Runs in CI pipeline on every push
- Tracks: bugs, vulnerabilities, code smells, coverage
- Quality gates block merges that don't meet thresholds
- Dashboard at your team's SonarQube instance

Key metrics to watch:
- **Reliability**: No new bugs introduced
- **Security**: No new vulnerabilities
- **Maintainability**: Technical debt ratio under threshold
- **Coverage**: Line and branch coverage maintained

### Combined review pipeline

```
Developer writes prompt
  -> Claude Code implements (with self-checks)
    -> /commit creates PR
      -> CodeRabbit auto-reviews
      -> SonarQube quality gate runs
      -> Human reviewer approves
        -> Merge
```

---

## 6. Human Review Checkpoints

Not everything can be automated. These require human judgment:

| Checkpoint | What to verify |
|------------|---------------|
| Architecture decisions | Does this approach fit the system? Could it cause issues at scale? |
| Business logic | Does the implementation match the actual business requirement? |
| Data handling | Is PII handled correctly? GDPR compliance? |
| API contracts | Will this break existing consumers? |
| Performance impact | Will this query scale? Is this O(n^2) hidden in a loop? |
| UX implications | Does the user flow still make sense? |

### When to pause and think

If Claude Code produces a solution that:
- Touches 10+ files - Review the approach, not just the diff
- Changes shared infrastructure - Get a second human opinion
- Modifies auth/payment/data flows - Full manual review required
- "Just works" on first try for complex features - Be extra skeptical

---

## 7. Advanced: Claude Code Bot (CI Integration)

Embed Claude Code as a bot in your repository. It picks up tasks via webhooks, implements them autonomously, and creates PRs for human review.

### Concept

```
Jira ticket transitions to "Ready" or GitHub issue labeled "ai-task"
  -> Webhook fires
    -> Claude Code bot picks up the task
      -> Creates branch, implements, runs tests
        -> Opens PR with implementation
          -> Standard review pipeline (CodeRabbit + human)
```

### Architecture

```
+---------------+     webhook      +--------------------+
|  Jira/GitHub  | ---------------> |  Task Queue        |
|  (trigger)    |                  |  (SQS/Redis)       |
+---------------+                  +---------+----------+
                                             |
                                             v
                                   +--------------------+
                                   |  Claude Code Bot   |
                                   |  (EC2/container)   |
                                   |                    |
                                   |  - Clones repo     |
                                   |  - Reads ticket    |
                                   |  - Plans approach  |
                                   |  - Implements      |
                                   |  - Runs tests      |
                                   |  - Creates PR      |
                                   +--------------------+
```

### Key considerations

- **Scoping**: Only allow well-defined, bounded tasks (bug fixes, small features)
- **Guardrails**: Bot runs with same hooks and rules as human developers
- **Review required**: Bot PRs always require human approval - never auto-merge
- **Cost control**: Set token limits per task, timeout after N minutes
- **Audit trail**: Every bot action logged for accountability

### Implementation approaches

| Approach | Complexity | Best for |
|----------|-----------|----------|
| GitHub Actions + `claude -p` | Low | Simple tasks triggered by labels |
| Dedicated worker + Claude API | Medium | Task queue with retry and monitoring |
| Claude Code SDK (Agent SDK) | High | Full autonomous agent with custom tools |

### GitHub Actions example (simplest)

```yaml
# .github/workflows/claude-bot.yml
name: Claude Code Bot
on:
  issues:
    types: [labeled]

jobs:
  implement:
    if: github.event.label.name == 'ai-task'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Claude Code
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          npm install -g @anthropic-ai/claude-code
          claude -p "Read issue #${{ github.event.issue.number }} and implement the requested change. Run tests before creating a PR."
      - name: Create PR
        uses: peter-evans/create-pull-request@v6
        with:
          title: "AI: ${{ github.event.issue.title }}"
          body: "Automated implementation of #${{ github.event.issue.number }}"
```

### Safety checklist for bot deployments

- [ ] Bot cannot push to main/master directly
- [ ] Bot PRs require at least 1 human approval
- [ ] Token/cost limits configured per task
- [ ] Timeout configured (e.g., 10 minutes max)
- [ ] Bot uses same linting/testing pipeline as humans
- [ ] Audit log captures all bot actions
- [ ] Kill switch to disable bot instantly
- [ ] Bot scope limited to specific repos/issue types
