# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an autonomous coding agent powered by the Claude Agent SDK. It builds complete applications over multiple sessions using a two-agent pattern:

1. **Initializer Agent** (first session): Reads the app spec, creates features in SQLite database, sets up project structure, and initializes git
2. **Coding Agent** (subsequent sessions): Picks up from previous sessions, implements features one-by-one, and marks them as passing

Progress persists via `features.db` (SQLite) and git commits. Sessions auto-continue with fresh context windows.

## Commands

```bash
# Start the launcher menu (creates venv, installs deps, shows menu)
./start.sh          # macOS/Linux
start.bat           # Windows

# Run agent directly on a project
python autonomous_agent_demo.py --project-dir generations/my-project

# Run a specific phase
python autonomous_agent_demo.py --project-dir generations/my-project --phase 2

# Limit iterations (useful for testing)
python autonomous_agent_demo.py --project-dir generations/my-project --max-iterations 5

# Run security tests
python -m pytest test_security.py -v
```

## Architecture

### Core Files

- `autonomous_agent_demo.py` - Entry point, parses args, calls `run_autonomous_agent()`
- `agent.py` - Main agent loop with session management, calls Claude SDK client
- `client.py` - Creates `ClaudeSDKClient` with security settings, MCP servers, and hooks
- `security.py` - Bash command allowlist validation hook (blocks non-allowed commands)
- `prompts.py` - Loads prompt templates with project-specific fallback chain
- `progress.py` - Progress tracking utilities, direct SQLite access for counts

### MCP Servers

The agent uses two MCP servers configured in `client.py`:

1. **features** (`mcp_server/feature_mcp.py`): Feature management via SQLite
   - `feature_get_stats` - Get passing/total counts
   - `feature_get_next` - Get next pending feature
   - `feature_mark_passing` - Mark feature as complete
   - `feature_create_bulk` - Bulk create features (initializer)
   - `feature_skip` - Move feature to end of queue

2. **playwright** (external): Browser automation for UI testing

### Database

Features are stored in `features.db` (SQLite) in each project directory. Schema defined in `api/database.py`:

```python
Feature(id, priority, category, name, description, steps, passes, phase)
```

### Prompt Templates

Located in `.claude/templates/`:
- `initializer_prompt.template.md` - First session prompt (creates features)
- `coding_prompt.template.md` - Continuation sessions (implements features)
- `phase_initializer_prompt.template.md` - Phase 2+ initialization

Project-specific prompts can override templates in `generations/{project}/prompts/`.

### Security Model (Defense in Depth)

1. **OS-level sandbox**: Bash commands run in isolated environment
2. **Filesystem restrictions**: File operations restricted to project directory via `.claude_settings.json`
3. **Bash allowlist**: Only specific commands permitted (see `ALLOWED_COMMANDS` in `security.py`)

The `bash_security_hook()` in `security.py` validates all bash commands before execution.

## Project Structure

```
generations/{project}/
├── features.db           # SQLite database (source of truth)
├── app_spec.txt          # Project specification
├── claude-progress.txt   # Session notes
├── init.sh               # Environment setup script
└── prompts/              # Project-specific prompts (optional)
    ├── app_spec.txt
    ├── initializer_prompt.md
    └── coding_prompt.md
```

## Key Patterns

### Two-Agent Pattern
- First run (no features in DB): Uses initializer prompt to create features
- Subsequent runs: Uses coding prompt to implement one feature at a time
- Each session gets a fresh context window

### Feature Workflow
1. Agent calls `feature_get_next` to get highest-priority pending feature
2. Implements the feature with code changes
3. Tests via Playwright browser automation
4. Calls `feature_mark_passing` after verification
5. Commits progress to git

### Phase System
- Phase 1 uses `app_spec.txt`
- Phase 2+ uses `phase{N}_spec.txt`
- Each phase has its own set of features in the database
- Phase N requires Phase N-1 to have started (has features)

## Versioning

The system uses semantic versioning to track compatibility between the system and generated projects.

### Files
- `VERSION` - Current system version (in repo root)
- `.version` - Project version (in each project directory)
- `CHANGELOG.md` - Version history and migration guides

### Functions (in `prompts.py`)
- `get_system_version()` - Returns current system version
- `get_project_version(project_dir)` - Returns version project was created with
- `stamp_project_version(project_dir)` - Stamps project with current version

### Upgrading Old Projects
1. Check project version: `cat generations/project/.version`
2. Read CHANGELOG.md for migration notes between versions
3. Apply migrations as needed
4. Update `.version` file to current version

### Versioning Workflow (IMPORTANT)

**When making changes to this repo, you MUST update versioning:**

1. **Determine version bump type:**
   - `PATCH` (1.0.0 → 1.0.1): Bug fixes, documentation, minor tweaks
   - `MINOR` (1.0.0 → 1.1.0): New features, new MCP tools, new prompt capabilities
   - `MAJOR` (1.0.0 → 2.0.0): Breaking changes (DB schema, removed features, prompt format changes)

2. **Update these files:**
   - `VERSION` - Update the version number
   - `CHANGELOG.md` - Add entry under `[Unreleased]` section with:
     - What changed (Added/Changed/Fixed/Removed)
     - Migration notes if projects need updates

3. **Breaking changes require migration notes:**
   - If DB schema changes: Document migration steps
   - If MCP tools change: Document old vs new tool names
   - If prompts change: Note what projects need to update

4. **Before committing, verify:**
   - [ ] VERSION file updated
   - [ ] CHANGELOG.md has entry for this change
   - [ ] Migration notes added if breaking change

**Example CHANGELOG entry:**
```markdown
## [Unreleased]

### Added
- New `feature_foo` MCP tool for X functionality

### Changed
- Updated `coding_prompt.template.md` to include Y

### Migration
- Projects using custom prompts should add Y to their prompts
```
