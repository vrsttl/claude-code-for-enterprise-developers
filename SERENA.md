# Serena: Semantic Code Analysis

Serena is an MCP plugin that gives Claude Code LSP-powered understanding of your codebase. Instead of text-matching with grep, Serena knows about symbols, types, references, and relationships - the same way your IDE does.

---

## Why Serena

Without Serena, Claude reads code as text. With Serena, Claude understands code as structure:

| What you ask | Without Serena | With Serena |
|--------------|----------------|-------------|
| "Find the UserService class" | Greps for the string, hopes for the best | Finds it by symbol with full type info |
| "What methods does this class have?" | Reads the entire file | Returns a structured overview instantly |
| "Who calls calculateSalary?" | Searches for the string across all files | Traces actual references through the type system |
| "Rename oldMethod to newMethod" | Search-and-replace, misses dynamic refs | Type-safe rename across the codebase |

## Setup

Serena is enabled as a plugin in `settings.json` (included in the starter kit):

```json
{
  "enabledPlugins": {
    "serena@claude-plugins-official": true
  }
}
```

No API keys needed. It runs locally via language servers.

## The Onboarding Step (Required Per Repo)

**Serena must be onboarded to each repository before it can work with it.** This is a one-time step per repo that teaches Serena the project's language server configuration.

### How to onboard

Just tell Claude:

> "Onboard Serena on the api-gateway repo"

Or if you're already working and Claude tries to use Serena on a repo it hasn't seen before, it will detect the missing onboarding and run it automatically.

Onboarding detects language servers (TypeScript, PHP, etc.) and creates config files.

### What onboarding creates

A `.serena/` directory in the repo root:

```
<repo>/
└── .serena/
    ├── project.yml     # Language server config, project name, ignored paths
    └── memories/       # Serena's project-specific memory store
```

The `project.yml` configures:
- Project name (matches repo folder name)
- Language server settings (auto-detected)
- Ignored paths (node_modules, vendor, etc.)
- Tool permissions (read/write modes)

**Commit `.serena/project.yml`** to git so teammates don't need to re-onboard.

## How to Use It

You don't call Serena tools directly - you just talk to Claude naturally. Claude decides when to use Serena under the hood.

### Exploring code

Ask questions like you would to a colleague who knows the codebase:

> "What classes are in UserController.php?"
>
> "Find the calculateSalary method in the billing-service repo"
>
> "Who calls the validateReview method? I need to understand the impact before changing it"
>
> "Show me all the Doctrine entities in user-service"
>
> "What's the structure of the SearchFilter class?"

Claude uses Serena's symbol tools behind the scenes to give you precise, type-aware answers.

### Making changes

When you ask Claude to modify code, include the repo reference so agents can activate Serena:

> "Fix the salary calculation bug in the billing-service repo"
>
> "Add a new endpoint to api-gateway for user preferences"
>
> "Rename the getProfile method to fetchProfile across the user-service repo"

Claude delegates to the appropriate agent (per delegation rules), and that agent uses Serena's editing tools for precise, LSP-aware modifications.

### Remembering patterns

Serena has its own per-project memory (separate from Claude Code's auto memory). Ask Claude to store patterns for a specific repo:

> "Remember that the billing-service repo uses a custom BigDecimal wrapper for all monetary calculations"
>
> "Save to Serena memory that api-gateway endpoints must go through the auth middleware"

This gets stored in `.serena/memories/` and is recalled when working on that repo.

## Agent Integration

When asking Claude to work on code, mention which repo so Serena can activate the right project:

> "Fix the salary calculation bug in the billing-service repo"
>
> "Rename getProfile to fetchProfile across the user-service repo"

Claude delegates to the appropriate agent, which activates Serena on that repo automatically. You don't need to specify "Serena project" or call any functions - just name the repo.

### What the main thread vs agents can do

| Who | Can do |
|-----|--------|
| You (main thread) | Read code, explore symbols, find references, search patterns |
| Implementation agents | Everything above + edit code, rename symbols, create files |
| code-reviewer agent | Read-only (same as main thread) |

This split is enforced by the delegation hook - the main thread coordinates, agents implement.

## One Project at a Time

Serena runs one language server at a time. If you're working across repos, Claude switches automatically:

> "Check the UserService in api-gateway, then look at how it's called from user-service"

Claude activates api-gateway first, gathers info, then switches to user-service. For parallel cross-repo work, use separate agent invocations - each agent gets its own Serena session.

## Troubleshooting

**"Project not found"**
- Tell Claude: "Onboard Serena on the [repo-name] repo"
- Check that `~/company/src/repo-name/.serena/project.yml` exists

**"Language server not started"**
- Tell Claude: "Restart the Serena language server"
- Check that the repo has the expected config (tsconfig.json for TypeScript, composer.json for PHP)

**Slow symbol resolution**
- Normal on first activation after restart (language server warming up)
- Subsequent queries are fast (cached)
- Large repos need proper `ignored_paths` in project.yml

**Stale results after git pull or IDE edits**
- Tell Claude: "Restart the Serena language server, I just pulled new changes"
- Serena tracks its own edits automatically, but external changes need a restart

## Quick Reference

| What you want | What to say |
|---------------|-------------|
| Onboard a new repo | "Onboard Serena on the api-gateway repo" |
| Explore a class | "What methods does UserService have?" |
| Find callers | "Who calls calculateSalary in the billing-service repo?" |
| Understand impact | "What would break if I change the ReviewDTO interface?" |
| Rename safely | "Rename getProfile to fetchProfile across the user-service repo" |
| Store a pattern | "Remember in Serena that this repo uses soft deletes for all entities" |
| Fix stale state | "Restart the Serena language server" |
