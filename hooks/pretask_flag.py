#!/usr/bin/env python3
"""
pretask_flag.py - PreToolUse Hook: Validates agent invocations and manages the subtask flag.

PURPOSE:
    This hook runs BEFORE every Agent/Task tool invocation. It does three things:
    1. VALIDATES the agent name against an allowlist (built from ~/.claude/agents/*.md)
    2. ENFORCES model tier (checks agent frontmatter declares the correct model)
    3. INCREMENTS a counter in .claude/.in_subtask.flag (the semaphore file)

AGENT VALIDATION:
    - Scans ~/.claude/agents/ for .md files. Each filename (minus .md) is an allowed agent.
    - Example: ~/.claude/agents/frontend-engineer.md -> "frontend-engineer" is allowed.
    - Hard-blocks generic agents like "Bash" or "general-purpose" to force named specialists.
    - If an unknown agent name is used, the hook rejects it and lists available agents.

MODEL ENFORCEMENT:
    - Each agent .md file can declare a model in YAML frontmatter:
        ---
        model: claude-sonnet-4-20250514
        ---
    - If the Task invocation requests a different model, the hook blocks it.
    - This ensures expensive models (Opus) are only used for agents that need them.

COUNTER MECHANISM:
    - The flag file (.claude/.in_subtask.flag) contains an integer counter.
    - Each agent start increments the counter (this hook).
    - Each agent stop decrements it (agent_stop.py).
    - When counter > 0, enforce_delegation.py allows mutation tools.
    - When counter reaches 0, the flag is deleted, re-engaging the block.
    - File locking (fcntl.flock) ensures atomic counter updates for parallel agents.
"""
import os
import sys
import fcntl
import json

# Path to the agents directory. Each .md file here registers an allowed agent name.
AGENTS_DIR = os.path.expanduser("~/.claude/agents")

def read_stdin():
    """Read and parse JSON from stdin. Claude Code sends hook context as JSON."""
    try:
        return json.loads(sys.stdin.read())
    except (json.JSONDecodeError, ValueError):
        return {}

def get_flag_path(data):
    """
    Derive the project-level flag path from the hook input.
    The flag lives at <project_cwd>/.claude/.in_subtask.flag
    so each project has its own independent semaphore.
    """
    cwd = data.get("cwd", os.getcwd())
    flag_dir = os.path.join(cwd, ".claude")
    os.makedirs(flag_dir, exist_ok=True)
    return os.path.join(flag_dir, ".in_subtask.flag")

def get_allowed_agents():
    """
    Build the allowlist of agent names from .md files in the agents directory.
    Also includes built-in utility types that don't need agent files.
    """
    allowed = set()
    if os.path.isdir(AGENTS_DIR):
        for f in os.listdir(AGENTS_DIR):
            if f.endswith(".md"):
                # Strip .md extension to get agent name
                allowed.add(f[:-3])
    # Built-in types that are always allowed (internal Claude Code utilities)
    allowed.update(["statusline-setup", "claude-code-guide", "Plan", "Explore"])
    return allowed

def check_blocked(data):
    """
    Reject non-allowlisted subagent_type values.
    This prevents the main thread from spawning unnamed or generic agents.
    """
    subagent = data.get("tool_input", {}).get("subagent_type", "")
    if not subagent:
        return

    # These generic names are never allowed - force the use of named specialists
    HARD_BLOCKED = {"Bash", "general-purpose"}
    if subagent in HARD_BLOCKED:
        print(
            f'BLOCKED: subagent_type "{subagent}" is not allowed. '
            "Use a named specialist agent (devops-engineer, frontend-engineer, etc.). "
            "See ~/.claude/rules/delegation.md for the agent selection matrix.",
            file=sys.stderr,
        )
        sys.exit(2)

    # Check against the dynamic allowlist built from agents/ directory
    allowed = get_allowed_agents()
    if subagent not in allowed:
        print(
            f'BLOCKED: subagent_type "{subagent}" not found in allowlist. '
            f"Available agents: {', '.join(sorted(allowed))}. "
            "Create ~/.claude/agents/{name}.md to register a new agent.",
            file=sys.stderr,
        )
        sys.exit(2)

def parse_frontmatter_model(filepath):
    """
    Extract the 'model' field from YAML frontmatter of an agent .md file.
    Frontmatter is delimited by --- markers at the start of the file.
    Returns None if no model is declared.
    """
    with open(filepath, 'r') as f:
        content = f.read()
    if not content.startswith('---'):
        return None
    end = content.find('---', 3)
    if end == -1:
        return None
    frontmatter = content[3:end]
    for line in frontmatter.split('\n'):
        line = line.strip()
        if line.startswith('model:'):
            return line.split(':', 1)[1].strip()
    return None

def check_model(data):
    """
    Enforce that the requested model matches the agent's declared model.
    Prevents accidentally running an agent on a more expensive model tier
    than what the agent definition specifies.
    """
    tool_input = data.get("tool_input", {})
    agent_name = tool_input.get("subagent_type", "")
    requested_model = tool_input.get("model", "")

    if not agent_name or not requested_model:
        return

    agent_file = os.path.join(AGENTS_DIR, f"{agent_name}.md")
    if not os.path.isfile(agent_file):
        return

    declared_model = parse_frontmatter_model(agent_file)
    if not declared_model:
        return

    # Block if there's a mismatch between requested and declared model
    if requested_model != declared_model:
        print(
            f'BLOCKED: Agent "{agent_name}" requires model "{declared_model}" '
            f'but was invoked with "{requested_model}". '
            f'Use model: "{declared_model}" for this agent.',
            file=sys.stderr,
        )
        sys.exit(2)

def increment_counter(flag_path):
    """
    Atomically increment the subtask counter in the flag file.
    Uses file locking (fcntl.flock) to handle concurrent agent spawns safely.
    The counter tracks how many agents are currently running.
    """
    fd = os.open(flag_path, os.O_RDWR | os.O_CREAT, 0o644)
    try:
        # Acquire exclusive lock to prevent race conditions
        fcntl.flock(fd, fcntl.LOCK_EX)
        raw = os.read(fd, 16).decode().strip()
        count = int(raw) if raw else 0
        # Reset file position, truncate, and write new count
        os.lseek(fd, 0, os.SEEK_SET)
        os.ftruncate(fd, 0)
        os.write(fd, str(count + 1).encode())
    finally:
        fcntl.flock(fd, fcntl.LOCK_UN)
        os.close(fd)

def main():
    data = read_stdin()
    check_blocked(data)     # Step 1: Validate agent name against allowlist
    check_model(data)       # Step 2: Enforce model tier from frontmatter
    flag = get_flag_path(data)
    increment_counter(flag)  # Step 3: Increment counter to signal "agent running"
    sys.exit(0)

if __name__ == "__main__":
    main()
