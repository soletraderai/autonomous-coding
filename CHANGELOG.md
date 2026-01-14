# Changelog

All notable changes to the Autonomous Coding Agent system will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## How to Use This Changelog

When updating an older project to work with a newer version of this system:

1. Check the project's `.version` file to see which version it was created with
2. Read through each version between that version and current
3. Follow the **Migration** notes for each version
4. Update the project's `.version` file to the new version

---

## [Unreleased]

### Added
- CHANGELOG.md for tracking system changes
- VERSION file for system versioning
- `.version` file stamped in new projects

### Fixed (Teachy App - Phase 4)
- **AT-1**: Removed redundant Home navigation button from Dashboard sidebar
- **AT-2**: Fixed Pro tier not registering in UI - added `INITIAL_SESSION` event handling in authStore to fetch fresh user data on page load
- **AT-3**: Fixed Feed page "Start Learning" navigation - passes `newSession` state to bypass Dashboard redirect
- **AT-4**: Fixed Start Learning button not working - added `newSession` state flag check in Home.tsx
- **AT-5**: Removed duplicate "Create First Session" section from Dashboard bottom
- **AT-6**: Fixed user data not persisting - added automatic `syncWithCloud()` call on auth events and app startup

### Changed (Teachy App)
- Auth state listener now handles `INITIAL_SESSION` event for page load with persisted sessions
- Token refresh now also updates user data to keep tier in sync
- Added `initializeAuth()` call and session sync on app startup in main.tsx

---

## [1.0.0] - 2025-01-11

First stable release. This version represents the current state of the system.

### Features
- Two-agent pattern (initializer + coding agent)
- Multi-phase support for incremental development
- MCP-based feature management (SQLite backend)
- Playwright browser automation for testing
- Security sandbox with bash command allowlist
- Project-specific prompt overrides
- `/create-spec` command for interactive spec generation
- N8N webhook integration for progress notifications

### Architecture
- `autonomous_agent_demo.py` - Entry point
- `agent.py` - Session management
- `client.py` - Claude SDK client configuration
- `security.py` - Bash security hook
- `prompts.py` - Prompt loading with fallback chain
- `progress.py` - Progress tracking utilities
- `mcp_server/feature_mcp.py` - Feature MCP server
- `api/database.py` - SQLAlchemy models

### Database Schema
```sql
CREATE TABLE features (
    id INTEGER PRIMARY KEY,
    priority INTEGER NOT NULL,
    category VARCHAR(100) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    steps JSON NOT NULL,
    passes BOOLEAN DEFAULT FALSE,
    phase INTEGER DEFAULT 1 NOT NULL
);
```

### MCP Tools
- `feature_get_stats` - Get passing/total counts
- `feature_get_next` - Get next pending feature
- `feature_get_for_regression` - Get random passing features
- `feature_mark_passing` - Mark feature as complete
- `feature_skip` - Move feature to end of queue
- `feature_create_bulk` - Bulk create features

---

## Pre-1.0 History

These are the major milestones before the 1.0.0 release. Projects created during
this period may need significant updates.

### 0.9.x - Phase Support (Late Development)
- Added `--phase` flag to support multi-phase development
- Added `phase` column to features table
- Added `phase_initializer_prompt.template.md`
- Added phase-specific spec files (`phase2_spec.txt`, etc.)

**Migration from pre-phase:**
- Run `api/migration.py` to add `phase` column to existing databases
- All existing features default to `phase=1`

### 0.8.x - MCP Migration
- Replaced FastAPI REST API with MCP server
- Feature tools now prefixed with `mcp__features__`
- Removed `/api/features/*` endpoints

**Migration from FastAPI:**
- No project changes needed - MCP server handles same database
- Prompt references to API endpoints should use MCP tools instead

### 0.7.x - Playwright Integration
- Added Playwright MCP server for browser automation
- Replaced previous testing approach with real browser testing
- Added `browser_*` tools for UI interaction

### 0.6.x - SQLite Migration
- Migrated from `feature_list.json` to SQLite database
- Added `api/database.py` with SQLAlchemy models
- Added automatic migration from JSON to SQLite

**Migration from JSON:**
- Automatic: `migrate_json_to_sqlite()` runs on startup
- `feature_list.json` is preserved but no longer used

### 0.5.x - Claude Agent SDK
- Migrated to `claude-agent-sdk` package
- Added security hooks for bash command validation
- Added sandbox mode

### 0.1.x - Initial Release
- Basic agent loop
- JSON-based feature storage
- Manual testing approach

---

## Version Compatibility Matrix

| System Version | DB Schema | Phase Support | MCP Server | Playwright |
|---------------|-----------|---------------|------------|------------|
| 1.0.0         | v2 (phase)| Yes           | Yes        | Yes        |
| 0.9.x         | v2 (phase)| Yes           | Yes        | Yes        |
| 0.8.x         | v1        | No            | Yes        | Yes        |
| 0.7.x         | v1        | No            | No (API)   | Yes        |
| 0.6.x         | v1        | No            | No (API)   | No         |
| < 0.6         | JSON      | No            | No (API)   | No         |

---

## Migration Guides

### Upgrading a Pre-1.0 Project to 1.0.0

1. **Check current state:**
   ```bash
   # Look for .version file
   cat generations/your-project/.version

   # If no .version file, check for indicators:
   ls generations/your-project/feature_list.json  # Pre-0.6 (JSON)
   ls generations/your-project/features.db        # 0.6+ (SQLite)
   ```

2. **Database migration** (if needed):
   - JSON → SQLite: Automatic on first run
   - Add phase column: Automatic via `migrate_add_phase_column()`

3. **Create .version file:**
   ```bash
   echo "1.0.0" > generations/your-project/.version
   ```

4. **Update prompts** (if using project-specific):
   - Copy latest templates from `.claude/templates/` to `prompts/`
   - Merge any customizations

### Starting Fresh with 1.0.0

New projects created via `./start.sh` or `/create-spec` will automatically:
- Get a `.version` file with current system version
- Use SQLite database with phase support
- Have access to all MCP tools
