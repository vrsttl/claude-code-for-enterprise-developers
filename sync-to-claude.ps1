#Requires -Version 5.1

<#
.SYNOPSIS
    Claude Code Onboarding - Sync Script (PowerShell)
.DESCRIPTION
    Syncs agents, rules, hooks, skills, examples, and settings to ~/.claude/
    Creates a backup first so you can revert.
.PARAMETER BackupOnly
    Only create backup, don't sync
.PARAMETER NoBackup
    Skip backup creation
.PARAMETER ListBackups
    List existing backups
#>

[CmdletBinding()]
param(
    [switch]$BackupOnly,
    [switch]$NoBackup,
    [switch]$ListBackups
)

$ErrorActionPreference = "Stop"

# Configuration
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$BackupDir = Join-Path $ClaudeDir "backups"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupName = "backup-$Timestamp"

function Write-Status { param([string]$Msg) Write-Host "[INFO] " -ForegroundColor Blue -NoNewline; Write-Host $Msg }
function Write-Ok { param([string]$Msg) Write-Host "[SUCCESS] " -ForegroundColor Green -NoNewline; Write-Host $Msg }
function Write-Warn { param([string]$Msg) Write-Host "[WARNING] " -ForegroundColor Yellow -NoNewline; Write-Host $Msg }
function Write-Err { param([string]$Msg) Write-Host "[ERROR] " -ForegroundColor Red -NoNewline; Write-Host $Msg }

function New-Backup {
    $BackupPath = Join-Path $BackupDir $BackupName
    Write-Status "Creating backup: $BackupPath"
    New-Item -ItemType Directory -Force -Path $BackupPath | Out-Null

    $items = 0
    $dirs = @("agents", "rules", "hooks", "skills", "examples")
    foreach ($dir in $dirs) {
        $src = Join-Path $ClaudeDir $dir
        if (Test-Path $src) {
            Copy-Item -Recurse -Force $src (Join-Path $BackupPath $dir)
            $items++
        }
    }

    $files = @("CLAUDE.md", "settings.json")
    foreach ($file in $files) {
        $src = Join-Path $ClaudeDir $file
        if (Test-Path $src) {
            Copy-Item -Force $src (Join-Path $BackupPath $file)
            $items++
        }
    }

    if ($items -gt 0) {
        Write-Ok "Backup completed ($items items)"
    } else {
        Write-Warn "No existing resources to backup"
        Remove-Item -Force -ErrorAction SilentlyContinue $BackupPath
    }
}

function Test-ExistingAgents {
    $agentsDir = Join-Path $ClaudeDir "agents"
    if (Test-Path $agentsDir) {
        $count = (Get-ChildItem -Path $agentsDir -Filter "*.md" -ErrorAction SilentlyContinue).Count
        if ($count -gt 10) {
            Write-Warn "You already have $count agents in ~/.claude/agents/"
            Write-Warn "This sync will ADD 6 starter agents (not replace your collection)"
            Write-Host "  Existing agents will be preserved. New agents with the same name will be overwritten." -ForegroundColor Yellow
            $reply = Read-Host "Continue? [y/N]"
            if ($reply -notmatch '^[Yy]$') {
                Write-Status "Aborted."
                exit 0
            }
        }
    }
}

function Sync-Resources {
    Write-Status "Syncing Claude Code onboarding resources..."
    New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null

    # CLAUDE.md
    $claudeMdSrc = Join-Path $ScriptDir "CLAUDE_GLOBAL.md"
    if (Test-Path $claudeMdSrc) {
        Write-Status "Syncing CLAUDE.md..."
        Copy-Item -Force $claudeMdSrc (Join-Path $ClaudeDir "CLAUDE.md")
        Write-Ok "Synced CLAUDE_GLOBAL.md -> ~/.claude/CLAUDE.md"
    } else {
        Write-Err "CLAUDE_GLOBAL.md not found in source"
        return $false
    }

    # Agents
    $agentsSrc = Join-Path $ScriptDir "agents"
    if (Test-Path $agentsSrc) {
        Write-Status "Syncing agents..."
        $agentsDst = Join-Path $ClaudeDir "agents"
        New-Item -ItemType Directory -Force -Path $agentsDst | Out-Null
        Copy-Item -Force (Join-Path $agentsSrc "*.md") $agentsDst
        $count = (Get-ChildItem -Path $agentsSrc -Filter "*.md").Count
        Write-Ok "Synced $count agents"
    }

    # Rules
    $rulesSrc = Join-Path $ScriptDir "rules"
    if (Test-Path $rulesSrc) {
        Write-Status "Syncing rules..."
        $rulesDst = Join-Path $ClaudeDir "rules"
        New-Item -ItemType Directory -Force -Path $rulesDst | Out-Null
        Copy-Item -Force (Join-Path $rulesSrc "*.md") $rulesDst
        $count = (Get-ChildItem -Path $rulesSrc -Filter "*.md").Count
        Write-Ok "Synced $count rule files"
    }

    # Hooks (Python - no chmod needed on Windows)
    $hooksSrc = Join-Path $ScriptDir "hooks"
    if (Test-Path $hooksSrc) {
        Write-Status "Syncing hooks..."
        $hooksDst = Join-Path $ClaudeDir "hooks"
        New-Item -ItemType Directory -Force -Path $hooksDst | Out-Null
        Copy-Item -Force (Join-Path $hooksSrc "*.py") $hooksDst
        # Note: On Unix, hooks need chmod +x. On Windows, Python handles execution.
        Write-Ok "Synced hooks"
    }

    # Skills (recursive - each skill is a directory)
    $skillsSrc = Join-Path $ScriptDir "skills"
    if (Test-Path $skillsSrc) {
        Write-Status "Syncing skills..."
        $skillsDst = Join-Path $ClaudeDir "skills"
        New-Item -ItemType Directory -Force -Path $skillsDst | Out-Null
        Copy-Item -Recurse -Force (Join-Path $skillsSrc "*") $skillsDst
        $count = (Get-ChildItem -Path $skillsDst -Directory).Count
        Write-Ok "Synced $count skills"
    }

    # Examples
    $examplesSrc = Join-Path $ScriptDir "examples"
    if (Test-Path $examplesSrc) {
        Write-Status "Syncing examples..."
        $examplesDst = Join-Path $ClaudeDir "examples"
        New-Item -ItemType Directory -Force -Path $examplesDst | Out-Null
        Copy-Item -Recurse -Force (Join-Path $examplesSrc "*") $examplesDst
        Write-Ok "Synced examples"
    }

    # settings.json
    $settingsSrc = Join-Path $ScriptDir "settings.json"
    if (Test-Path $settingsSrc) {
        Write-Status "Syncing settings.json..."
        Copy-Item -Force $settingsSrc (Join-Path $ClaudeDir "settings.json")
        Write-Ok "Synced settings.json"
    }

    return $true
}

function Test-Sync {
    Write-Status "Validating sync..."
    $errors = 0
    $warnings = 0

    # Agent count
    $agentsSrc = Join-Path $ScriptDir "agents"
    if (Test-Path $agentsSrc) {
        $count = (Get-ChildItem -Path $agentsSrc -Filter "*.md").Count
        if ($count -lt 6) {
            Write-Warn "Expected 6 starter agents in source, found: $count"
            $warnings++
        }
    }

    # Hooks
    @("enforce_delegation.py", "pretask_flag.py", "agent_stop.py") | ForEach-Object {
        if (-not (Test-Path (Join-Path $ClaudeDir "hooks" $_))) {
            Write-Err "$_ hook missing"
            $errors++
        }
    }

    # CLAUDE.md
    $claudeMd = Join-Path $ClaudeDir "CLAUDE.md"
    if (-not (Test-Path $claudeMd) -or (Get-Item $claudeMd).Length -eq 0) {
        Write-Err "CLAUDE.md is missing or empty"
        $errors++
    }

    # settings.json
    if (-not (Test-Path (Join-Path $ClaudeDir "settings.json"))) {
        Write-Err "settings.json missing"
        $errors++
    }

    # Rules directory
    if (-not (Test-Path (Join-Path $ClaudeDir "rules"))) {
        Write-Warn "Rules directory missing"
        $warnings++
    }

    if ($errors -eq 0) {
        Write-Ok "Validation passed ($warnings warnings)"
        return $true
    } else {
        Write-Err "Validation failed ($errors errors, $warnings warnings)"
        return $false
    }
}

# Main
if ($ListBackups) {
    if (Test-Path $BackupDir) {
        Get-ChildItem -Path $BackupDir -Directory | Format-Table Name, LastWriteTime
    } else {
        Write-Host "No backups"
    }
    exit 0
}

Write-Host "================================================================"
Write-Host "Claude Code Onboarding - Sync"
Write-Host "================================================================"
Write-Host ""
Write-Status "Source: $ScriptDir"
Write-Status "Target: $ClaudeDir"
Write-Host ""

if ($BackupOnly) {
    New-Backup
    exit 0
}

Test-ExistingAgents

if (-not $NoBackup) {
    New-Backup
    Write-Host ""
}

if (Sync-Resources) {
    Write-Host ""
    if (Test-Sync) {
        Write-Host ""
        Write-Ok "Sync complete!"
        Write-Host ""
        Write-Status "Summary:"
        Write-Host "  - CLAUDE_GLOBAL.md -> ~/.claude/CLAUDE.md"
        Write-Host "  - Agents synced to ~/.claude/agents/"
        Write-Host "  - Rules synced to ~/.claude/rules/"
        Write-Host "  - Hooks synced to ~/.claude/hooks/"
        Write-Host "  - Skills synced to ~/.claude/skills/"
        Write-Host "  - Examples synced to ~/.claude/examples/"
        Write-Host "  - settings.json -> ~/.claude/settings.json"
        Write-Host ""
        Write-Status "Next steps:"
        Write-Host "  1. Review the synced agents in ~/.claude/agents/"
        Write-Host "  2. Try: claude 'use frontend-engineer to create a React component'"
        Write-Host "  3. Observe how hooks enforce delegation patterns"
    } else {
        exit 1
    }
} else {
    Write-Err "Sync failed"
    exit 1
}
