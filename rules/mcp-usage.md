# MCP Usage Rules

## On-Demand Loading

MCPs are NOT in global settings to prevent credential leakage.

| MCP | Purpose | Credentials |
|-----|---------|-------------|
| Atlassian | Jira, Confluence | Required |
| Perplexity | Deep research | Required |
| Serena | Semantic LSP (ONE project) | None |
| Playwright | Browser automation | None |
| Context7 | Real-time docs | None |

## Launch Commands

```bash
~/.claude/scripts/mcp/launch-<name>-mcp.sh
~/.claude/scripts/mcp/launch-all-mcps.sh
```

## Serena Usage

**CRITICAL: Serena handles ONE project at a time.**

Working directory structure:
```
~/agentic-working/week-XX/DD-MM-YY/TICKET-###/
```

Launch from working directory (NOT repo):
```bash
~/.claude/scripts/mcp/launch-serena-mcp.sh $(pwd)
```

## MCP Resources

Reference with `@` autocomplete: `@server:protocol://path`

## Atlassian Cloud ID

**CRITICAL: Always use this cloud ID for ALL Atlassian MCP calls (Jira + Confluence).**

| Key | Value |
|-----|-------|
| Cloud ID | `<your-atlassian-cloud-id>` |
| Site | your-company.atlassian.net |

Do NOT call `getAccessibleAtlassianResources` to discover the ID - use the value above directly.

## Best Practices

- MCPs should be lightweight gateways, not abstraction layers
- Use `.mcp.json` for project-scope (checked into git)
- Use `~/.claude.json` for user-scope (personal tools)
