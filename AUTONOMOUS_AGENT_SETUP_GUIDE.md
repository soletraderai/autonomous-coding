# Autonomous Agent Fork & Customization Guide

## Overview

This guide covers the complete workflow for:

1. Forking the `leonvanzyl/autonomous-coding` repository
2. Creating your own customized version with multi-phase support
3. Keeping your fork synced with upstream changes
4. Using Claude Code to analyze upstream changes before merging
5. Deploying the agent to individual client projects

---

## Table of Contents

- [Part 1: Initial Setup - Forking & Tracking Upstream](#part-1-initial-setup---forking--tracking-upstream)
- [Part 2: Implementing Multi-Phase Support](#part-2-implementing-multi-phase-support)
- [Part 3: Ongoing - Syncing Upstream Changes](#part-3-ongoing---syncing-upstream-changes)
- [Part 4: Using Your Custom Agent Per Project](#part-4-using-your-custom-agent-per-project)
- [Part 5: Quick Reference Commands](#part-5-quick-reference-commands)
- [Part 6: Automation Scripts](#part-6-automation-scripts)
- [Appendix A: Claude Code Prompts](#appendix-a-claude-code-prompts)
- [Appendix B: PRD for Multi-Phase Support](#appendix-b-prd-for-multi-phase-support)

---

## Part 1: Initial Setup - Forking & Tracking Upstream

### Step 1.1: Fork the Original Repo on GitHub

1. Go to https://github.com/leonvanzyl/autonomous-coding
2. Click **Fork** (top right)
3. Select your GitHub account
4. You now have: `github.com/YOUR_USERNAME/autonomous-coding`

### Step 1.2: Clone Your Fork Locally

```bash
# Create a directory for your tools
mkdir -p ~/tools
cd ~/tools

# Clone YOUR fork (not the original)
git clone git@github.com:YOUR_USERNAME/autonomous-coding.git soletrader-autonomous-agent
cd soletrader-autonomous-agent
```

### Step 1.3: Add the Original as "Upstream" Remote

```bash
# Add the original repo as a remote called "upstream"
git remote add upstream https://github.com/leonvanzyl/autonomous-coding.git

# Verify you have both remotes
git remote -v

# Should show:
# origin    git@github.com:YOUR_USERNAME/autonomous-coding.git (fetch)
# origin    git@github.com:YOUR_USERNAME/autonomous-coding.git (push)
# upstream  https://github.com/leonvanzyl/autonomous-coding.git (fetch)
# upstream  https://github.com/leonvanzyl/autonomous-coding.git (push)
```

### Step 1.4: Create Your Development Branch

```bash
# Create a branch for your customizations
git checkout -b soletrader-main

# Push this branch to your fork
git push -u origin soletrader-main
```

### Branch Structure Explanation

```
YOUR FORK (origin)                    ORIGINAL (upstream)
github.com/you/autonomous-coding      github.com/leonvanzyl/autonomous-coding
         │                                      │
         │                                      │
    ┌────┴────┐                                 │
    │         │                                 │
  master    soletrader-main                  master
    │         │                                 │
    │         └── Your phase support            │
    │             customizations                │
    │                                           │
    └───────────── Syncs with ─────────────────┘
```

- `master` - Stays in sync with upstream (Leon's repo)
- `soletrader-main` - Your customized version with phase support

---

## Part 2: Implementing Multi-Phase Support

### Step 2.1: Set Up the Development Environment

```bash
cd ~/tools/soletrader-autonomous-agent

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Step 2.2: Use Claude Code to Implement the PRD

```bash
# Make sure you're on your custom branch
git checkout soletrader-main

# Open Claude Code in the repo
claude
```

**In Claude Code, use this prompt:**

```
I need you to implement the multi-phase project continuation system for this autonomous coding agent.

The complete PRD is provided below. Before making any changes:

1. Read and understand all existing files in this repo
2. Confirm you understand the current architecture
3. Then implement the changes file by file, testing as you go
4. DO NOT GUESS - verify each change works before proceeding
5. Run all tests specified in the PRD before marking complete

Start by exploring the codebase and confirming your understanding.

[PASTE THE CONTENTS OF APPENDIX B: PRD FOR MULTI-PHASE SUPPORT]
```

### Step 2.3: Commit Your Changes

```bash
# After Claude Code finishes and tests pass
git add .
git commit -m "feat: Add multi-phase project continuation support

- Add --phase CLI flag to autonomous_agent_demo.py
- Add phase-aware feature tracking in progress.py
- Add phase spec loading in prompts.py
- Add phase_initializer_prompt template
- Update MCP server for phase column support"

# Push to your fork
git push origin soletrader-main
```

---

## Part 3: Ongoing - Syncing Upstream Changes

This is the critical workflow for keeping your fork updated while protecting your customizations.

### Step 3.1: Fetch Upstream Changes (Do This Regularly)

```bash
cd ~/tools/soletrader-autonomous-agent
source venv/bin/activate

# Fetch latest from upstream (doesn't change your code yet)
git fetch upstream
```

### Step 3.2: Check What Changed

```bash
# See commits in upstream that you don't have
git log master..upstream/master --oneline

# See the actual file changes
git diff master..upstream/master --stat

# See detailed changes to a specific file
git diff master..upstream/master -- agent.py
```

### Step 3.3: Update Your Master Branch

```bash
# Switch to master
git checkout master

# Fast-forward to match upstream
git pull upstream master

# Push updated master to your fork
git push origin master
```

### Step 3.4: Analyze Impact on Your Custom Branch with Claude Code

This is where Claude Code helps you analyze compatibility before merging.

```bash
# Switch to your custom branch
git checkout soletrader-main

# See what would change if you merged
git diff soletrader-main..master --stat

# Open Claude Code for analysis
claude
```

**Use the upstream analysis prompt from Appendix A.**

### Step 3.5: Merge Upstream Changes (When Safe)

```bash
# If Claude Code says it's safe:
git checkout soletrader-main
git merge master

# If there are conflicts, Claude Code can help resolve them
# After resolving:
git add .
git commit -m "merge: Incorporate upstream updates from leonvanzyl/autonomous-coding"
git push origin soletrader-main
```

### Step 3.6: If Conflicts Occur

```bash
# Start the merge
git merge master

# If conflicts appear, open Claude Code
claude
```

**Use this prompt:**

```
I have merge conflicts after merging upstream changes. Please help me resolve them.

Run `git status` to see the conflicted files, then for each file:
1. Show me the conflict markers
2. Explain what upstream changed vs what my customization does
3. Recommend the best resolution that preserves both improvements
4. Make the fix

After all conflicts are resolved, run the test suite to verify everything works.
```

---

## Part 4: Using Your Custom Agent Per Project

### Step 4.1: Create a New Client Project

```bash
# Create the project directory
mkdir -p ~/projects/client-name
cd ~/projects/client-name
git init

# Copy your autonomous agent into the project
cp -r ~/tools/soletrader-autonomous-agent .autonomous

# Remove the engine's git history (it's now part of this project)
rm -rf .autonomous/.git
rm -rf .autonomous/venv
rm -rf .autonomous/generations

# Create a project-local venv
cd .autonomous
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cd ..

# Create your prompts directory
mkdir -p prompts
```

### Step 4.2: Create Your App Spec

```bash
cat > prompts/app_spec.txt << 'EOF'
<app_spec>
# Project Name: [Client Name]

## Overview
[Describe the project]

## Core Features
[List the main features]

## Tech Stack
- Frontend: [e.g., Next.js, React, Vue]
- Backend: [e.g., Node.js, Python, etc.]
- Database: [e.g., PostgreSQL, MongoDB]
- Styling: [e.g., Tailwind CSS]

## User Roles
[Define user types and permissions]

## Pages/Views
[List main pages]

## API Endpoints
[List main endpoints if applicable]

</app_spec>
EOF
```

### Step 4.3: Run Phase 1

```bash
cd ~/projects/client-name
source .autonomous/venv/bin/activate

# Run the agent for Phase 1
python3 .autonomous/autonomous_agent_demo.py --project-dir .
```

### Step 4.4: Create Phase 2 Spec (After Phase 1 Completes)

```bash
cat > prompts/phase2_spec.txt << 'EOF'
# Phase 2 Requirements

## New Features
- [Feature 1]
- [Feature 2]

## Enhancements to Existing Features
- [Enhancement 1]
- [Enhancement 2]

## Technical Improvements
- [Improvement 1]

## Notes
- [Any special considerations]

EOF
```

### Step 4.5: Run Phase 2

```bash
python3 .autonomous/autonomous_agent_demo.py --project-dir . --phase 2
```

### Step 4.6: Repeat for Additional Phases

```bash
# Create phase3_spec.txt, phase4_spec.txt, etc.
# Then run:
python3 .autonomous/autonomous_agent_demo.py --project-dir . --phase 3
```

---

## Part 5: Quick Reference Commands

### Daily Workflow Cheatsheet

```bash
# ===== CHECK FOR UPSTREAM UPDATES =====
cd ~/tools/soletrader-autonomous-agent
git fetch upstream
git log master..upstream/master --oneline

# ===== ANALYZE UPDATES WITH CLAUDE CODE =====
git checkout soletrader-main
claude
# Use the analysis prompt from Appendix A

# ===== MERGE UPDATES (if safe) =====
git checkout master
git pull upstream master
git push origin master
git checkout soletrader-main
git merge master
git push origin soletrader-main

# ===== START NEW CLIENT PROJECT =====
mkdir -p ~/projects/new-client && cd ~/projects/new-client
git init
cp -r ~/tools/soletrader-autonomous-agent .autonomous
rm -rf .autonomous/.git .autonomous/venv .autonomous/generations
cd .autonomous && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt && cd ..
mkdir prompts
# Create prompts/app_spec.txt

# ===== RUN AGENT =====
source .autonomous/venv/bin/activate
python3 .autonomous/autonomous_agent_demo.py --project-dir .           # Phase 1
python3 .autonomous/autonomous_agent_demo.py --project-dir . --phase 2  # Phase 2
python3 .autonomous/autonomous_agent_demo.py --project-dir . --phase 3  # Phase 3
```

### Project Structure Reference

```
~/projects/client-name/
├── .autonomous/              ← Your forked engine
│   ├── agent.py
│   ├── prompts.py
│   ├── progress.py
│   ├── client.py
│   ├── autonomous_agent_demo.py
│   ├── mcp_server/
│   ├── .claude/
│   │   └── templates/
│   │       ├── initializer_prompt.template.md
│   │       ├── coding_prompt.template.md
│   │       └── phase_initializer_prompt.template.md
│   ├── requirements.txt
│   └── venv/
├── prompts/
│   ├── app_spec.txt          ← Phase 1 specification
│   ├── phase2_spec.txt       ← Phase 2 specification
│   └── phase3_spec.txt       ← Phase 3 specification
├── features.db               ← Feature tracking database
├── src/                      ← Generated application code
├── package.json
└── README.md
```

---

## Part 6: Automation Scripts

### Script 1: Check Upstream (`check-upstream.sh`)

Save this in `~/tools/soletrader-autonomous-agent/check-upstream.sh`:

```bash
#!/bin/bash
# check-upstream.sh - Check for upstream changes and summarize

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔍 Checking for upstream changes..."
echo ""

# Fetch upstream
git fetch upstream

# Count new commits
NEW_COMMITS=$(git rev-list master..upstream/master --count)

if [ "$NEW_COMMITS" -eq "0" ]; then
    echo "✅ Your fork is up to date with upstream!"
    exit 0
fi

echo "⚠️  Found $NEW_COMMITS new commit(s) in upstream"
echo ""
echo "📋 New commits:"
git log master..upstream/master --oneline
echo ""
echo "📁 Files changed:"
git diff master..upstream/master --stat
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Next steps:"
echo ""
echo "1. Analyze changes with Claude Code:"
echo "   git checkout soletrader-main"
echo "   claude"
echo "   # Use the upstream analysis prompt"
echo ""
echo "2. Update master branch:"
echo "   git checkout master"
echo "   git pull upstream master"
echo "   git push origin master"
echo ""
echo "3. Merge to your branch (if safe):"
echo "   git checkout soletrader-main"
echo "   git merge master"
echo "   git push origin soletrader-main"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

Make it executable:

```bash
chmod +x ~/tools/soletrader-autonomous-agent/check-upstream.sh
```

### Script 2: New Project Setup (`new-project.sh`)

Save this in `~/tools/soletrader-autonomous-agent/new-project.sh`:

```bash
#!/bin/bash
# new-project.sh - Set up a new client project with the autonomous agent

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <project-name>"
    echo "Example: $0 client-dashboard"
    exit 1
fi

PROJECT_NAME="$1"
PROJECT_DIR=~/projects/"$PROJECT_NAME"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Creating new project: $PROJECT_NAME"
echo ""

# Create project directory
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Initialize git
git init

# Copy the autonomous agent
echo "📦 Copying autonomous agent..."
cp -r "$SCRIPT_DIR" .autonomous

# Clean up
rm -rf .autonomous/.git
rm -rf .autonomous/venv
rm -rf .autonomous/generations
rm -f .autonomous/check-upstream.sh
rm -f .autonomous/new-project.sh

# Create project-local venv
echo "🐍 Setting up Python environment..."
cd .autonomous
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt --quiet
cd ..

# Create prompts directory
mkdir -p prompts

# Create template app_spec.txt
cat > prompts/app_spec.txt << 'EOF'
<app_spec>
# Project Name: PROJECT_NAME_PLACEHOLDER

## Overview
[Describe what this application does]

## Core Features
- [Feature 1]
- [Feature 2]
- [Feature 3]

## Tech Stack
- Frontend: Next.js 14 with App Router
- Styling: Tailwind CSS
- Backend: Node.js API routes
- Database: [Your choice]

## User Roles
- [Role 1]: [Permissions]
- [Role 2]: [Permissions]

## Pages/Views
1. [Page 1] - [Description]
2. [Page 2] - [Description]

## API Endpoints
- GET /api/[resource] - [Description]
- POST /api/[resource] - [Description]

</app_spec>
EOF

# Replace placeholder with actual project name
sed -i "s/PROJECT_NAME_PLACEHOLDER/$PROJECT_NAME/g" prompts/app_spec.txt

# Create .gitignore
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
.autonomous/venv/

# Build outputs
.next/
dist/
build/

# Environment
.env
.env.local
.env.*.local

# Database
*.db

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*
EOF

# Create README
cat > README.md << EOF
# $PROJECT_NAME

## Development

### Running the Autonomous Agent

\`\`\`bash
source .autonomous/venv/bin/activate
python3 .autonomous/autonomous_agent_demo.py --project-dir .
\`\`\`

### Phase 2 and Beyond

1. Create \`prompts/phase2_spec.txt\` with Phase 2 requirements
2. Run: \`python3 .autonomous/autonomous_agent_demo.py --project-dir . --phase 2\`

## Project Structure

- \`prompts/\` - Project specifications per phase
- \`.autonomous/\` - The autonomous coding agent
- \`src/\` - Generated application code
EOF

echo ""
echo "✅ Project created successfully!"
echo ""
echo "📁 Location: $PROJECT_DIR"
echo ""
echo "Next steps:"
echo "1. cd $PROJECT_DIR"
echo "2. Edit prompts/app_spec.txt with your project details"
echo "3. source .autonomous/venv/bin/activate"
echo "4. python3 .autonomous/autonomous_agent_demo.py --project-dir ."
echo ""
```

Make it executable:

```bash
chmod +x ~/tools/soletrader-autonomous-agent/new-project.sh
```

### Using the Scripts

```bash
# Check for upstream updates
~/tools/soletrader-autonomous-agent/check-upstream.sh

# Create a new client project
~/tools/soletrader-autonomous-agent/new-project.sh awesome-client-app
```

---

## Appendix A: Claude Code Prompts

### Prompt 1: Upstream Change Analysis

Use this prompt when upstream has changes you need to evaluate:

```
I need you to analyze upstream changes to the autonomous-coding repo and assess their impact on my customizations.

## Context
I have a forked version of leonvanzyl/autonomous-coding with custom multi-phase support.
The upstream repo has been updated and I need to determine if it's safe to merge.

## My Customizations (soletrader-main branch)
- Added --phase CLI flag to autonomous_agent_demo.py
- Added phase-aware functions to progress.py (has_features, count_passing_tests, is_phase_complete, get_current_phase)
- Added phase spec loading to prompts.py (get_phase_spec, get_phase_initializer_prompt)
- Added phase_initializer_prompt.template.md template
- Added phase column to features database schema

## Your Task

1. Run: `git diff soletrader-main..master --stat` to see changed files
2. Run: `git diff soletrader-main..master` to see full diff
3. For EACH changed file, analyze:
   - What specifically changed in upstream?
   - Does this file contain my phase support customizations?
   - Will merging cause conflicts?
   - Is this a bug fix, new feature, or refactor?

4. Provide a clear recommendation:

   **SAFE TO MERGE** - No conflicts with phase support
   - List the changes and why they're safe

   **MERGE WITH CAUTION** - Minor adjustments needed
   - List the specific adjustments required after merge
   
   **MANUAL REVIEW REQUIRED** - Significant conflicts expected
   - Explain the conflicts
   - Provide step-by-step resolution plan

5. If recommending merge, provide the exact commands:
   ```bash
   git checkout master
   git pull upstream master
   git push origin master
   git checkout soletrader-main
   git merge master
   # any additional steps
   ```

Begin by running the git diff commands.
```

### Prompt 2: Conflict Resolution

Use this when you have merge conflicts:

```
I have merge conflicts after attempting to merge upstream changes. Help me resolve them.

## Instructions

1. Run `git status` to identify all conflicted files
2. For each conflicted file:
   a. Show me the content with conflict markers
   b. Explain what upstream changed
   c. Explain what my customization does
   d. Recommend the best resolution that:
      - Preserves my phase support functionality
      - Incorporates the upstream improvement
   e. Make the fix using the Edit tool

3. After all conflicts are resolved:
   a. Run `git add .`
   b. Run syntax checks on all Python files
   c. Run any available tests
   d. If all passes, commit with message: "merge: Resolve conflicts with upstream, preserve phase support"

Be thorough - missing a conflict will break the system.
```

### Prompt 3: Implement Phase Support (Initial Setup)

Use this to implement the multi-phase system for the first time:

```
I need you to implement the multi-phase project continuation system for this autonomous coding agent.

## Critical Instructions

1. **DO NOT GUESS** - If unsure how something works, read the code first
2. **TEST INCREMENTALLY** - Verify each change before proceeding
3. **PRESERVE BACKWARD COMPATIBILITY** - Existing projects must continue to work
4. **CHECK YOUR WORK** - Run syntax checks after every file modification

## Implementation Order

1. First: Read ALL existing files to understand the architecture
2. Second: Modify prompts.py (lowest risk - new functions only)
3. Third: Modify progress.py (utility function updates)
4. Fourth: Create phase_initializer_prompt.template.md
5. Fifth: Modify agent.py (core logic changes)
6. Sixth: Modify autonomous_agent_demo.py (CLI flag)
7. Seventh: Update MCP server if needed
8. Eighth: Run ALL verification tests
9. Ninth: Fix any issues
10. Tenth: Re-verify until all tests pass

## Verification Tests (MUST ALL PASS)

1. Fresh project Phase 1 works
2. Phase 1 continuation works  
3. Premature Phase 2 shows error
4. Missing phase spec shows error
5. Phase 2 initialization works
6. Phase 2 continuation works
7. Legacy projects still work

Start by exploring the codebase. List each file and summarize its purpose before making any changes.

[PASTE THE FULL PRD FROM APPENDIX B BELOW]
```

---

## Appendix B: PRD for Multi-Phase Support

**Note:** The complete PRD is provided as a separate file: `PHASE_CONTINUATION_PRD.md`

When using Claude Code to implement the phase support, paste the entire contents of that PRD file after the prompt in Appendix A, Prompt 3.

The PRD contains:

1. Current System Architecture analysis
2. Problem Statement
3. Solution Overview
4. Detailed Functional Requirements
5. Implementation Specification with code examples
6. File-by-File Changes
7. Testing & Validation Protocol
8. Acceptance Criteria

---

## Appendix C: Troubleshooting

### Issue: "Command not found: claude"

```bash
# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Or if using Homebrew
brew install claude-code
```

### Issue: Git permission denied

```bash
# Make sure your SSH key is set up
ssh -T git@github.com

# If not, generate and add a key
ssh-keygen -t ed25519 -C "your@email.com"
cat ~/.ssh/id_ed25519.pub
# Add this to GitHub → Settings → SSH Keys
```

### Issue: Python module not found

```bash
# Make sure you're in the right venv
which python3
# Should show: .../venv/bin/python3

# If not, activate it
source venv/bin/activate  # or .autonomous/venv/bin/activate
```

### Issue: Phase 2 won't start

```bash
# Check Phase 1 completion
cd ~/projects/your-project
source .autonomous/venv/bin/activate
python3 -c "
from progress import count_passing_tests, is_phase_complete
from pathlib import Path
p = Path('.')
passing, total = count_passing_tests(p, phase=1)
print(f'Phase 1: {passing}/{total} passing')
print(f'Complete: {is_phase_complete(p, 1)}')
"
```

### Issue: Merge conflicts seem impossible

```bash
# Nuclear option: preserve your changes, start fresh
git checkout soletrader-main
git branch backup-soletrader-main  # Safety backup

# Get a clean master
git checkout master
git reset --hard upstream/master
git push origin master --force

# Recreate your branch from master and re-apply changes
git checkout -b soletrader-main-v2
# Then use Claude Code to re-implement changes with the PRD
```

---

## Quick Start Checklist

- [ ] Fork `leonvanzyl/autonomous-coding` on GitHub
- [ ] Clone your fork to `~/tools/soletrader-autonomous-agent`
- [ ] Add upstream remote
- [ ] Create `soletrader-main` branch
- [ ] Set up Python venv and install dependencies
- [ ] Use Claude Code to implement phase support (Appendix A, Prompt 3 + Appendix B)
- [ ] Commit and push your customizations
- [ ] Create `check-upstream.sh` script
- [ ] Create `new-project.sh` script
- [ ] Create your first client project and test the workflow

---

**Document Version:** 1.0  
**Last Updated:** January 2025  
**Maintainer:** Soletrader.ai
