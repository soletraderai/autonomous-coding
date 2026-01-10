#!/bin/bash
# setup.sh - Interactive setup for new autonomous coding projects
# Usage: ./setup.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get current directory as default
CURRENT_DIR="$(pwd)"
PROJECT_NAME=$(basename "$CURRENT_DIR")

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         Autonomous Coding Agent - Project Setup            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Get project path (default to current directory)
echo -e "${GREEN}Enter project path:${NC}"
echo -e "${YELLOW}(Press Enter for current directory: ${CURRENT_DIR})${NC}"
read -p "> " PROJECT_PATH

if [ -z "$PROJECT_PATH" ]; then
    PROJECT_PATH="$CURRENT_DIR"
else
    # Expand ~ if used
    PROJECT_PATH="${PROJECT_PATH/#\~/$HOME}"
fi

# Get project name from path
PROJECT_NAME=$(basename "$PROJECT_PATH")

echo ""
echo -e "${BLUE}Project: ${PROJECT_NAME}${NC}"
echo -e "${BLUE}Location: ${PROJECT_PATH}${NC}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Check if .autonomous already exists
if [ -d "$PROJECT_PATH/.autonomous" ]; then
    echo -e "${RED}Error: .autonomous already exists in $PROJECT_PATH${NC}"
    exit 1
fi

# Find best Python (prefer 3.12, 3.11, then fall back to python3)
if command -v python3.12 &> /dev/null; then
    PYTHON_CMD="python3.12"
elif command -v python3.11 &> /dev/null; then
    PYTHON_CMD="python3.11"
elif command -v /usr/local/bin/python3.12 &> /dev/null; then
    PYTHON_CMD="/usr/local/bin/python3.12"
elif command -v /usr/local/bin/python3.11 &> /dev/null; then
    PYTHON_CMD="/usr/local/bin/python3.11"
else
    PYTHON_CMD="python3"
fi

echo ""
echo -e "${BLUE}Using Python: $($PYTHON_CMD --version)${NC}"

# Create project directory if it doesn't exist
mkdir -p "$PROJECT_PATH"
cd "$PROJECT_PATH"

# Clone the template
echo -e "${BLUE}Cloning autonomous-coding template...${NC}"
git clone git@github.com:soletraderai/autonomous-coding.git .autonomous

# Set up Python environment
echo -e "${BLUE}Setting up Python environment...${NC}"
cd .autonomous
$PYTHON_CMD -m venv venv
source venv/bin/activate
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
deactivate
cd "$PROJECT_PATH"

# Create prompts directory and starter app_spec.txt
echo -e "${BLUE}Creating starter files...${NC}"
mkdir -p prompts

cat > prompts/app_spec.txt << 'SPEC_EOF'
<project_specification>
# Project Name

## Overview
Describe your application here.

## Core Features
- Feature 1
- Feature 2
- Feature 3

## Tech Stack
- Frontend: Next.js, React, Tailwind CSS
- Backend: (if needed)

## User Interface
Describe the main pages/views and their layouts.

## Additional Requirements
Any other requirements or constraints.
</project_specification>
SPEC_EOF

# Initialize git repo if not already a git repo
if [ ! -d ".git" ]; then
    echo -e "${BLUE}Initializing git repository...${NC}"
    git init --quiet
fi

# Create/update .gitignore
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'GITIGNORE_EOF'
.autonomous/
node_modules/
.env
.env.local
.next/
dist/
build/
GITIGNORE_EOF
else
    # Append .autonomous/ if not already in .gitignore
    if ! grep -q "^\.autonomous/" .gitignore 2>/dev/null; then
        echo ".autonomous/" >> .gitignore
    fi
fi

# Create README if it doesn't exist
if [ ! -f "README.md" ]; then
    cat > README.md << README_EOF
# $PROJECT_NAME

Built with [Autonomous Coding Agent](https://github.com/soletraderai/autonomous-coding)

## Getting Started

1. Edit \`prompts/app_spec.txt\` with your project requirements
2. Run the agent:
   \`\`\`bash
   source .autonomous/venv/bin/activate
   python .autonomous/autonomous_agent_demo.py --project-dir . --phase 1
   \`\`\`

## Multi-Phase Development

For additional features after Phase 1:
1. Create \`prompts/phase2_spec.txt\` with new requirements
2. Run: \`python .autonomous/autonomous_agent_demo.py --project-dir . --phase 2\`
README_EOF
fi

# Done!
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Setup Complete!                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Project created at: ${BLUE}$PROJECT_PATH${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Edit prompts/app_spec.txt with your project requirements"
echo "  2. Run the agent:"
echo ""
echo -e "     ${GREEN}source .autonomous/venv/bin/activate${NC}"
echo -e "     ${GREEN}python .autonomous/autonomous_agent_demo.py --project-dir . --phase 1${NC}"
echo ""
