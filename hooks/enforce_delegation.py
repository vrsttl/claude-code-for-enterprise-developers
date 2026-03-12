#!/usr/bin/env python3
"""
enforce_delegation.py - PreToolUse Hook: Blocks mutation tools on the main thread.

PURPOSE:
    This hook enforces the "main thread coordinates, agents implement" pattern.
    The main (orchestrator) thread should NEVER directly edit files, run shell
    commands, or use Serena mutation tools. Instead, it must delegate those
    actions to specialist agents (e.g., frontend-engineer, staff-php-developer).

HOW IT WORKS:
    1. Claude Code calls this hook BEFORE executing any tool in the BLOCKED dict.
    2. The hook checks for a semaphore file: .claude/.in_subtask.flag
       - If the flag EXISTS -> we are inside an agent (subtask), so ALLOW the tool.
       - If the flag is MISSING -> we are on the main thread, so BLOCK the tool.
    3. The flag file is created by pretask_flag.py (PreToolUse on Agent/Task)
       and removed by agent_stop.py (SubagentStop) when agents finish.
    4. Special case: Write is allowed in plan mode for plan files (~/.claude/plans/).

SEMAPHORE FILE (.claude/.in_subtask.flag):
    - Created by pretask_flag.py when an agent starts
    - Contains a counter (e.g., "2") tracking concurrent running agents
    - Decremented by agent_stop.py when agents finish
    - Deleted when counter reaches 0 (all agents done)
    - Cleaned up on SessionStart to prevent stale flags
"""
import os
import json
import sys

# Map of blocked tools -> suggested agent to delegate to.
# When the main thread tries to use one of these tools, the hook prints
# an error message suggesting which agent should handle the work instead.
BLOCKED = {
    # Shell commands should be delegated to a DevOps specialist
    "Bash": "devops-engineer",
    # File editing tools should be delegated to the appropriate code specialist
    "Edit": "frontend-engineer or staff-php-developer",
    "Write": "frontend-engineer or staff-php-developer",
    "MultiEdit": "frontend-engineer or staff-php-developer",
    # Notebook editing should be delegated to a data specialist
    "NotebookEdit": "data-scientist (not included in starter kit)",
    # Serena MCP mutation tools - same delegation rules apply
    "mcp__plugin_serena_serena__execute_shell_command": "devops-engineer",
    "mcp__plugin_serena_serena__replace_content": "frontend-engineer or staff-php-developer",
    "mcp__plugin_serena_serena__replace_symbol_body": "frontend-engineer or staff-php-developer",
    "mcp__plugin_serena_serena__insert_after_symbol": "frontend-engineer or staff-php-developer",
    "mcp__plugin_serena_serena__insert_before_symbol": "frontend-engineer or staff-php-developer",
    "mcp__plugin_serena_serena__rename_symbol": "frontend-engineer or staff-php-developer",
    "mcp__plugin_serena_serena__delete_lines": "frontend-engineer or staff-php-developer",
    "mcp__plugin_serena_serena__create_text_file": "frontend-engineer or staff-php-developer",
    "mcp__plugin_serena_serena__edit_memory": "frontend-engineer or staff-php-developer",
    "mcp__plugin_serena_serena__delete_memory": "frontend-engineer or staff-php-developer",
    "mcp__plugin_serena_serena__insert_at_line": "frontend-engineer or staff-php-developer",
    "mcp__plugin_serena_serena__replace_lines": "frontend-engineer or staff-php-developer",
}

def main():
    # Read the hook input from stdin (JSON with tool_name, tool_input, cwd, etc.)
    try:
        data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        data = {}

    # Determine the project working directory and the path to the semaphore flag
    cwd = data.get("cwd", os.getcwd())
    flag = os.path.join(cwd, ".claude", ".in_subtask.flag")

    # If the flag file exists, we are inside an agent subtask - allow everything
    if os.path.exists(flag):
        sys.exit(0)

    tool = data.get("tool_name", "")

    # Special case: Allow Write tool in plan mode for writing plan files.
    # This lets the main thread save plan documents without delegation.
    permission_mode = data.get("permission_mode", "")
    if permission_mode == "plan" and tool == "Write":
        tool_input = data.get("tool_input", {})
        file_path = tool_input.get("file_path", "")
        plans_dir = os.path.expanduser("~/.claude/plans/")
        if file_path.startswith(plans_dir):
            sys.exit(0)

    # If the tool is in the blocked list, reject it with a helpful message
    if tool in BLOCKED:
        print(f"BLOCKED: {tool} not allowed on main thread. Delegate to {BLOCKED[tool]}.", file=sys.stderr)
        # Exit code 2 tells Claude Code to reject the tool call
        sys.exit(2)

    # Tool not in blocked list - allow it
    sys.exit(0)

if __name__ == "__main__":
    main()
