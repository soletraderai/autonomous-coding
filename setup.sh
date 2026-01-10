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

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         Autonomous Coding Agent - Project Setup            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Get project name
echo -e "${GREEN}What's your project name?${NC}"
read -p "> " PROJECT_NAME

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}Error: Project name cannot be empty${NC}"
    exit 1
fi

# Sanitize project name (replace spaces with hyphens, lowercase)
PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-_')

# Get location
echo ""
echo -e "${GREEN}Where should the project be created?${NC}"
echo -e "${YELLOW}(Press Enter for default: ~/Web)${NC}"
read -p "> " PROJECT_LOCATION

if [ -z "$PROJECT_LOCATION" ]; then
    PROJECT_LOCATION="$HOME/Web"
fi

# Expand ~ if used
PROJECT_LOCATION="${PROJECT_LOCATION/#\~/$HOME}"

# Full project path
PROJECT_PATH="$PROJECT_LOCATION/$PROJECT_NAME"

echo ""
echo -e "${BLUE}Project will be created at: ${PROJECT_PATH}${NC}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Check if directory already exists
if [ -d "$PROJECT_PATH" ]; then
    echo -e "${RED}Error: Directory already exists: $PROJECT_PATH${NC}"
    exit 1
fi

# Create project directory
echo ""
echo -e "${BLUE}Creating project directory...${NC}"
mkdir -p "$PROJECT_PATH"
cd "$PROJECT_PATH"

# Clone the template
echo -e "${BLUE}Cloning autonomous-coding template...${NC}"
git clone git@github.com:soletraderai/autonomous-coding.git .autonomous

# Set up Python environment
echo -e "${BLUE}Setting up Python environment...${NC}"
cd .autonomous
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt --quiet
cd ..

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

# Initialize git repo for the project
git init --quiet
echo ".autonomous/" >> .gitignore
echo "node_modules/" >> .gitignore
echo ".env" >> .gitignore
echo ".env.local" >> .gitignore

# Create a simple README
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

# Done!
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Setup Complete!                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Project created at: ${BLUE}$PROJECT_PATH${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. cd $PROJECT_PATH"
echo "  2. Edit prompts/app_spec.txt with your project requirements"
echo "  3. Run the agent:"
echo ""
echo -e "     ${GREEN}source .autonomous/venv/bin/activate${NC}"
echo -e "     ${GREEN}python .autonomous/autonomous_agent_demo.py --project-dir . --phase 1${NC}"
echo ""
