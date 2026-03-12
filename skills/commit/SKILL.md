---
name: commit
description: "Guided git commit workflow. Triggers on '/commit'. Analyzes staged changes, generates commit message, and creates the commit."
version: 1.0.0
---

# Guided Git Commit

Analyzes staged and unstaged changes, generates a conventional commit message, and creates the commit.

## Variables

- **message_override** (optional): Custom commit message to use instead of auto-generated

## Workflow

### Step 1: Check Git Status

Run `git status` and `git diff --cached --stat` to see staged changes.
If nothing staged, run `git diff --stat` to show unstaged changes and ask what to stage.

### Step 2: Analyze Changes

Read the diffs to understand what changed:
- Identify the type: feat, fix, refactor, docs, test, chore
- Identify the scope (which component/module)
- Summarize the change in 1 line

### Step 3: Generate Commit Message

Format: `type(scope): description`

Examples:
- `feat(salaries): add salary comparison chart component`
- `fix(auth): handle expired token refresh correctly`
- `refactor(search): extract filter logic into custom hook`

Present the message to the user for approval.

### Step 4: Create Commit

```bash
git commit -m "the approved message"
```

Show the commit hash and summary.

## Example Invocations

- `/commit` - Auto-analyze and commit
- `/commit -m "fix: resolve login redirect loop"` - Use provided message
