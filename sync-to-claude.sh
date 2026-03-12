#!/bin/bash

# Claude Code Onboarding - Sync Script
# Syncs agents, rules, hooks, skills, examples, and settings to ~/.claude/
#
# This script copies the starter kit resources into your Claude Code
# configuration directory. It creates a backup first so you can revert.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$CLAUDE_DIR/backups"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_NAME="backup-${TIMESTAMP}"

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

create_backup() {
    local backup_path="$BACKUP_DIR/$BACKUP_NAME"
    print_status "Creating backup: $backup_path"
    mkdir -p "$backup_path"

    local items=0
    [ -d "$CLAUDE_DIR/agents" ] && cp -r "$CLAUDE_DIR/agents" "$backup_path/" && items=$((items + 1))
    [ -d "$CLAUDE_DIR/rules" ] && cp -r "$CLAUDE_DIR/rules" "$backup_path/" && items=$((items + 1))
    [ -d "$CLAUDE_DIR/hooks" ] && cp -r "$CLAUDE_DIR/hooks" "$backup_path/" && items=$((items + 1))
    [ -d "$CLAUDE_DIR/skills" ] && cp -r "$CLAUDE_DIR/skills" "$backup_path/" && items=$((items + 1))
    [ -d "$CLAUDE_DIR/examples" ] && cp -r "$CLAUDE_DIR/examples" "$backup_path/" && items=$((items + 1))
    [ -f "$CLAUDE_DIR/CLAUDE.md" ] && cp "$CLAUDE_DIR/CLAUDE.md" "$backup_path/" && items=$((items + 1))
    [ -f "$CLAUDE_DIR/settings.json" ] && cp "$CLAUDE_DIR/settings.json" "$backup_path/" && items=$((items + 1))

    if [ $items -gt 0 ]; then
        print_success "Backup completed ($items items)"
    else
        print_warning "No existing resources to backup"
        rmdir "$backup_path" 2>/dev/null || true
    fi
}

check_existing_agents() {
    # Warn if the user already has a large collection of agents
    if [ -d "$CLAUDE_DIR/agents" ]; then
        local existing_count
        existing_count=$(find "$CLAUDE_DIR/agents" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$existing_count" -gt 10 ]; then
            print_warning "You already have $existing_count agents in ~/.claude/agents/"
            print_warning "This sync will ADD 6 starter agents (not replace your collection)"
            echo -e "${YELLOW}  Existing agents will be preserved. New agents with the same name will be overwritten.${NC}"
            echo
            read -p "Continue? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_status "Aborted."
                exit 0
            fi
        fi
    fi
}

sync_resources() {
    print_status "Syncing Claude Code onboarding resources..."
    mkdir -p "$CLAUDE_DIR"

    # CLAUDE.md (global config - most important file)
    if [ -f "$SCRIPT_DIR/CLAUDE_GLOBAL.md" ]; then
        print_status "Syncing CLAUDE.md..."
        cp "$SCRIPT_DIR/CLAUDE_GLOBAL.md" "$CLAUDE_DIR/CLAUDE.md"
        print_success "Synced CLAUDE_GLOBAL.md → ~/.claude/CLAUDE.md"
    else
        print_error "CLAUDE_GLOBAL.md not found in source"
        return 1
    fi

    # Agents (starter kit of 5)
    if [ -d "$SCRIPT_DIR/agents" ]; then
        print_status "Syncing agents..."
        mkdir -p "$CLAUDE_DIR/agents"
        cp "$SCRIPT_DIR/agents"/*.md "$CLAUDE_DIR/agents/" 2>/dev/null || true
        local count
        count=$(find "$SCRIPT_DIR/agents" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        print_success "Synced $count agents"
    fi

    # Rules
    if [ -d "$SCRIPT_DIR/rules" ]; then
        print_status "Syncing rules..."
        mkdir -p "$CLAUDE_DIR/rules"
        cp "$SCRIPT_DIR/rules"/*.md "$CLAUDE_DIR/rules/" 2>/dev/null || true
        local count
        count=$(find "$SCRIPT_DIR/rules" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        print_success "Synced $count rule files"
    fi

    # Hooks (Python)
    if [ -d "$SCRIPT_DIR/hooks" ]; then
        print_status "Syncing hooks..."
        mkdir -p "$CLAUDE_DIR/hooks"
        cp "$SCRIPT_DIR/hooks"/*.py "$CLAUDE_DIR/hooks/" 2>/dev/null || true
        chmod +x "$CLAUDE_DIR/hooks"/*.py 2>/dev/null || true
        local count
        count=$(find "$CLAUDE_DIR/hooks" -name "*.py" -newer "$SCRIPT_DIR/hooks" -o -name "*.py" 2>/dev/null | wc -l | tr -d ' ')
        print_success "Synced hooks (executable)"
    fi

    # Skills
    if [ -d "$SCRIPT_DIR/skills" ]; then
        print_status "Syncing skills..."
        mkdir -p "$CLAUDE_DIR/skills"
        cp -r "$SCRIPT_DIR/skills"/* "$CLAUDE_DIR/skills/" 2>/dev/null || true
        local count
        count=$(find "$CLAUDE_DIR/skills" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
        print_success "Synced $count skills"
    fi

    # Examples
    if [ -d "$SCRIPT_DIR/examples" ]; then
        print_status "Syncing examples..."
        mkdir -p "$CLAUDE_DIR/examples"
        cp -r "$SCRIPT_DIR/examples"/* "$CLAUDE_DIR/examples/" 2>/dev/null || true
        print_success "Synced examples"
    fi

    # settings.json
    if [ -f "$SCRIPT_DIR/settings.json" ]; then
        print_status "Syncing settings.json..."
        cp "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"
        print_success "Synced settings.json"
    fi
}

validate_sync() {
    print_status "Validating sync..."
    local errors=0
    local warnings=0

    # Agent count (expect 5 from starter kit)
    local agent_count
    agent_count=$(find "$SCRIPT_DIR/agents" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$agent_count" -lt 6 ]; then
        print_warning "Expected 6 starter agents in source, found: $agent_count"
        warnings=$((warnings + 1))
    fi

    # Hooks exist
    if [ ! -f "$CLAUDE_DIR/hooks/enforce_delegation.py" ]; then
        print_error "enforce_delegation.py hook missing"
        errors=$((errors + 1))
    fi
    if [ ! -f "$CLAUDE_DIR/hooks/pretask_flag.py" ]; then
        print_error "pretask_flag.py hook missing"
        errors=$((errors + 1))
    fi
    if [ ! -f "$CLAUDE_DIR/hooks/agent_stop.py" ]; then
        print_error "agent_stop.py hook missing"
        errors=$((errors + 1))
    fi

    # CLAUDE.md exists
    if [ ! -f "$CLAUDE_DIR/CLAUDE.md" ] || [ ! -s "$CLAUDE_DIR/CLAUDE.md" ]; then
        print_error "CLAUDE.md is missing or empty"
        errors=$((errors + 1))
    fi

    # Settings exist
    if [ ! -f "$CLAUDE_DIR/settings.json" ]; then
        print_error "settings.json missing"
        errors=$((errors + 1))
    fi

    # Rules directory exists
    if [ ! -d "$CLAUDE_DIR/rules" ]; then
        print_warning "Rules directory missing"
        warnings=$((warnings + 1))
    fi

    if [ $errors -eq 0 ]; then
        print_success "Validation passed ($warnings warnings)"
        return 0
    else
        print_error "Validation failed ($errors errors, $warnings warnings)"
        return 1
    fi
}

show_help() {
    echo "Claude Code Onboarding - Sync Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help"
    echo "  --backup-only  Only create backup"
    echo "  --no-backup    Skip backup"
    echo "  --list-backups List backups"
    echo
    echo "Syncs to ~/.claude/:"
    echo "  - 6 starter agents"
    echo "  - Rules (delegation, code-quality)"
    echo "  - 3 Python hooks (delegation enforcement)"
    echo "  - Skills (commit, review-pr, tdd, create-agent)"
    echo "  - Examples (ticket-workspace)"
    echo "  - settings.json"
}

main() {
    echo "================================================================"
    echo "Claude Code Onboarding - Sync"
    echo "================================================================"
    echo
    print_status "Source: $SCRIPT_DIR"
    print_status "Target: $CLAUDE_DIR"
    echo

    check_existing_agents
    create_backup
    echo

    if sync_resources; then
        echo
        if validate_sync; then
            echo
            print_success "Sync complete!"
            echo
            print_status "Summary:"
            echo "  - CLAUDE_GLOBAL.md → ~/.claude/CLAUDE.md"
            echo "  - Agents synced to ~/.claude/agents/"
            echo "  - Rules synced to ~/.claude/rules/"
            echo "  - Hooks synced to ~/.claude/hooks/"
            echo "  - Skills synced to ~/.claude/skills/"
            echo "  - Examples synced to ~/.claude/examples/"
            echo "  - settings.json -> ~/.claude/settings.json"
            echo
            print_status "Next steps:"
            echo "  1. Review the synced agents in ~/.claude/agents/"
            echo "  2. Try: claude 'use frontend-engineer to create a React component'"
            echo "  3. Observe how hooks enforce delegation patterns"
        else
            exit 1
        fi
    else
        print_error "Sync failed"
        exit 1
    fi
}

case "${1:-}" in
    -h|--help) show_help; exit 0 ;;
    --backup-only) create_backup; exit 0 ;;
    --list-backups) ls -la "$BACKUP_DIR" 2>/dev/null || echo "No backups"; exit 0 ;;
    --no-backup) sync_resources && validate_sync; exit $? ;;
    "") main ;;
    *) print_error "Unknown: $1"; show_help; exit 1 ;;
esac
