---
name: review-pr
description: "Review a GitHub pull request. Triggers on '/review-pr'. Fetches PR details, analyzes changes, and provides a structured review. Use when asked to 'review PR', 'check this PR', or given a PR URL/number."
version: 1.0.0
---

# Pull Request Review

Fetches a GitHub PR, analyzes the changes, and provides a structured code review.

## Variables

- **pr_identifier** (required): PR number or URL (e.g., "123" or "https://github.com/org/repo/pull/123")
- **repo** (optional): Repository in org/repo format (inferred from current git remote if not provided)

## Workflow

### Step 1: Fetch PR Details

```bash
gh pr view {pr_identifier} --json title,body,files,additions,deletions,commits,author
gh pr diff {pr_identifier}
```

### Step 2: Analyze Changes

For each changed file:
1. Read the diff
2. Check for: security issues, performance concerns, code style, test coverage
3. Note any missing tests for new functionality

### Step 3: Delegate Deep Review

```
Agent("code-reviewer", "
  Review the following PR changes:

  PR: {title}
  Author: {author}
  Files changed: {file_list}

  {full diff content}

  Provide structured review with:
  - Critical issues (must fix)
  - Suggestions (nice to have)
  - Questions for the author
  - Overall assessment
")
```

### Step 4: Present Review

```markdown
## PR Review: {title}

**Author:** {author} | **Files:** {count} | **+{additions} -{deletions}**

### Critical Issues
- [ ] {issue with file:line reference}

### Suggestions
- {suggestion with rationale}

### Questions
- {question about design decision}

### Verdict: {Approve | Request Changes | Comment}
```

## Example Invocations

- `/review-pr 456` - Review PR #456 in current repo
- `/review-pr https://github.com/your-org/api-gateway/pull/789` - Review specific PR
- "review the latest PR on api-gateway" - Contextual invocation
