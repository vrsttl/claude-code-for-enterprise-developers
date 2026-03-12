---
name: create-agent
description: "Guided agent creation with domain research, rules compilation, and MCP tool selection. ALWAYS use this skill when the user wants to create, build, make, add, or set up a new agent or specialist for any domain. This includes any request describing a new autonomous worker they want added to their setup, even if they don't use the word 'agent' explicitly - phrases like 'I need something that can handle X', 'set up a specialist for Y', 'I want a dedicated worker for Z', or describing a new capability they want to delegate to an autonomous process. Also trigger for: 'I need an agent that can...', 'build me an agent for...', 'create a specialist for...', 'add an agent that...', 'make an agent to...', 'set up an agent for...', or any request that involves defining a new Claude Code sub-agent with specific domain knowledge, tool access, and behavioral rules. This skill handles the full workflow: interviewing the user for domain knowledge and MCP plugin requirements, researching the domain, compiling a rules.md, getting user approval, then invoking agent-creator. Do NOT trigger for: modifying existing agents, listing agents, asking what agents are available, running/invoking existing agents, debugging agent issues, or deleting agents."
---

# Guided Agent Creation

Create high-quality agents by front-loading the knowledge gathering. An agent is only as good as the rules it operates under. This skill ensures those rules are comprehensive before any code gets written.

The workflow has two phases: first you build the knowledge base (rules.md), then agent-creator builds the agent using it.

## Variables

Extract from the user's request:

- **agent_purpose** (required): What the agent should do
- **agent_name** (optional): Desired name, or derive from purpose
- **target_repos** (optional): Which repositories the agent will work with
- **model_tier** (optional): Opus, Sonnet, or Haiku. Default: infer from complexity

## Phase 1: Knowledge Gathering

### Step 1: Intake Interview

Ask the user these questions. Don't dump them all at once - have a conversation. Skip questions the user already answered in their initial request.

**Core identity:**
- What domain does this agent specialize in? (e.g., "payment processing", "search infrastructure", "design system maintenance")
- What specific tasks should it handle? List 3-5 concrete examples.
- What should it explicitly NOT do? (boundaries matter as much as capabilities)

**Technical context:**
- Which repositories will it work with? What tech stack?
- Are there existing patterns, conventions, or architectural decisions it needs to follow?
- What test frameworks, build tools, or CI pipelines does it need to know about?
- Are there internal tools, services, or APIs it should be aware of?

**Tool & plugin access:**
- Which MCP plugins does this agent need? (e.g., Serena for semantic code analysis, Atlassian for Jira/Confluence, Playwright for browser automation, Context7 for library docs, Figma for design specs, Perplexity for deep research)
- Does it need shell access (Bash tool)?
- Does it need file write access (Edit/Write tools), or should it be read-only?
- Are there tools it should explicitly NOT have? (principle of least privilege - only grant what's needed)

This matters because agents only get the tools listed in their definition. Missing a plugin means the agent can't use it; granting too many creates unnecessary risk.

**Quality standards:**
- What does "good output" look like for this agent's domain?
- Are there common mistakes or anti-patterns to avoid?
- What review criteria should its work be evaluated against?
- Are there compliance, security, or performance requirements?

**Team context:**
- Is there a Confluence space, wiki, or shared doc with domain knowledge?
- Are there existing agents whose patterns this one should follow?
- Who reviews this agent's work and what do they care about?

Collect answers. The user doesn't need to answer everything - fill gaps with research in the next step.

### Step 2: Domain Research

Based on the intake, research to fill knowledge gaps. Use available tools:

- **Codebase**: Read existing code in target repos to understand patterns, conventions, tech stack
- **Existing agents**: Read agents in `~/.claude/agents/` that work in similar domains - extract patterns worth reusing
- **Web research**: Look up best practices, framework conventions, common pitfalls for the domain
- **Confluence/docs**: If the user mentioned internal docs, fetch them

Focus on gathering actionable rules - things that would prevent the agent from making mistakes or producing inconsistent output.

### Step 3: Compile rules.md

Write a `rules.md` file that captures everything learned. Save it to a temporary location the user can review.

Structure:

```markdown
# Rules: {agent_name}

## Domain Context
Brief description of what this agent does and why these rules exist.

## Architecture & Patterns
- How code is structured in this domain
- Naming conventions
- File organization patterns
- Key abstractions and their relationships

## Technical Standards
- Framework-specific conventions
- Testing requirements
- Error handling patterns
- Performance expectations

## Boundaries
- What this agent handles vs. what it delegates
- Files/modules it should never modify
- Operations that require human approval

## Common Pitfalls
- Known anti-patterns in this domain
- Things that look right but are wrong
- Edge cases that frequently cause bugs

## Verification
- How to check the agent's work
- Test commands to run
- Quality criteria to meet
```

Not every section needs content. Only include what's relevant. The rules should be specific and actionable, not generic advice.

### Step 4: User Review

Present the compiled rules.md to the user. Show it inline (don't just say "I wrote a file").

Ask: "Here's the rules.md I've compiled for the {agent_name} agent. Does this capture your domain knowledge accurately? Anything to add, change, or remove?"

Wait for approval. If the user has changes, incorporate them and show the updated version.

Do NOT proceed to Phase 2 until the user confirms the rules are good.

## Phase 2: Agent Creation

### Step 5: Prepare the agent-creator brief

Once rules are approved, build the agent-creator invocation. The brief should include:

- Agent name and purpose
- Model tier (Opus for implementation-heavy, Sonnet for domain specialists, Haiku for utilities)
- Tool requirements (what MCP tools, file access, shell access does it need?)
- The approved rules.md content - this becomes the agent's core knowledge
- Which existing agent to use as a structural template (pick the closest match from `~/.claude/agents/`)
- Where to save: `~/.claude/agents/{agent-name}.md`

### Step 6: Invoke agent-creator

Delegate to the agent-creator agent:

```
Agent("agent-creator", "
  Create a new agent with the following specification:

  Name: {agent_name}
  Model: {model_tier}
  Purpose: {agent_purpose}
  Tools: {tool_list}
  Save to: ~/.claude/agents/{agent_name}.md

  Use {template_agent} as a structural reference for the agent definition format.

  The following rules.md contains the domain knowledge this agent needs.
  Embed the key rules directly into the agent definition - don't reference
  an external file. The agent should carry its knowledge with it.

  --- RULES ---
  {rules_md_content}
  --- END RULES ---

  After creating the agent:
  1. Verify the file was written
  2. Report the agent's capabilities summary
")
```

### Step 7: Report

Tell the user:
- Agent created at `~/.claude/agents/{agent_name}.md`
- Summary of capabilities
- How to invoke: `Agent("{agent_name}", "task description")`
- Suggest a test task to verify it works

## Example Flow

**User**: "I need an agent for managing our Elasticsearch indices in the search service"

**Intake** (abbreviated):
- Domain: Elasticsearch index management
- Tasks: Create/update mappings, reindex, optimize queries, manage aliases
- Not for: Application code changes, frontend search UI
- Repos: ~/company/src/web-app/, ~/company/src/search-service/
- Stack: ES 8.x, PHP client
- Standards: Zero-downtime reindexing, alias-based deployments

**Research**: Reads web-app repo for existing ES patterns, checks existing agents for similar domain scope, looks up ES 8.x best practices.

**rules.md**: Compiled with specific index patterns, mapping conventions, reindex procedures used in the codebase.

**Review**: User confirms, adds a note about a custom analyzer they use.

**Agent creation**: agent-creator produces `elasticsearch-admin.md` with the domain knowledge baked in.
