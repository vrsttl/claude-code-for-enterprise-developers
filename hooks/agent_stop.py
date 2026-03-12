#!/usr/bin/env python3
"""
agent_stop.py - SubagentStop Hook: Decrements the subtask counter when an agent finishes.

PURPOSE:
    This hook runs when ANY agent (foreground or background) completes its work.
    It decrements the counter in .claude/.in_subtask.flag and cleans up the flag
    file when all agents have finished, which re-engages the delegation enforcement.

COUNTER DECREMENT LOGIC:
    - Read the current count from .claude/.in_subtask.flag
    - Subtract 1 from the count
    - If count <= 0: DELETE the flag file entirely
      (This re-enables enforce_delegation.py blocking on the main thread)
    - If count > 0: Write the new count back to the file
      (Other agents are still running, so keep the flag alive)

FLAG FILE CLEANUP:
    - The flag file is the semaphore that enforce_delegation.py checks.
    - When deleted, the main thread can no longer use mutation tools directly.
    - This ensures the "delegate, don't implement" pattern is re-engaged
      as soon as all agents are done.
    - File locking ensures safe concurrent decrements when multiple agents
      finish around the same time.
"""
import json
import os
import sys
import fcntl

def main():
    # Read hook input from stdin
    try:
        data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, TypeError, ValueError):
        data = {}

    # Locate the flag file in the project's .claude/ directory
    cwd = data.get("cwd", os.getcwd())
    flag = os.path.join(cwd, ".claude", ".in_subtask.flag")

    # If no flag file exists, nothing to decrement - exit cleanly
    if not os.path.exists(flag):
        sys.exit(0)

    fd = os.open(flag, os.O_RDWR, 0o644)
    try:
        # Acquire exclusive lock for safe concurrent access
        fcntl.flock(fd, fcntl.LOCK_EX)
        raw = os.read(fd, 16).decode().strip()
        count = int(raw) if raw else 0
        count -= 1

        if count <= 0:
            # All agents are done - remove the flag file entirely.
            # This re-engages enforce_delegation.py on the main thread.
            fcntl.flock(fd, fcntl.LOCK_UN)
            os.close(fd)
            try:
                os.remove(flag)
            except OSError:
                pass
            sys.exit(0)

        # Other agents still running - write decremented count back
        os.lseek(fd, 0, os.SEEK_SET)
        os.ftruncate(fd, 0)
        os.write(fd, str(count).encode())
    finally:
        # Clean up file descriptor (may already be closed if count <= 0)
        try:
            fcntl.flock(fd, fcntl.LOCK_UN)
            os.close(fd)
        except OSError:
            pass
    sys.exit(0)

if __name__ == "__main__":
    main()
