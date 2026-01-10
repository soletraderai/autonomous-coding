#!/bin/bash
# new-project.sh - Set up a new client project with the autonomous agent
# Usage: ./new-project.sh <project-name> [--location <path>]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Default project location
PROJECT_BASE=~/projects

# Parse arguments
PROJECT_NAME=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --location)
            PROJECT_BASE="$2"
            shift 2
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
        *)
            PROJECT_NAME="$1"
            shift
            ;;
    esac
done

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${BOLD}${BLUE}New Project Setup${NC}"
    echo ""
    echo "Usage: $0 <project-name> [--location <path>]"
    echo ""
    echo "Examples:"
    echo "  $0 client-dashboard"
    echo "  $0 my-app --location ~/workspace"
    exit 1
fi

PROJECT_DIR="$PROJECT_BASE/$PROJECT_NAME"

echo ""
echo -e "${BOLD}${BLUE}=====================================================${NC}"
echo -e "${BOLD}${BLUE}          NEW PROJECT SETUP                          ${NC}"
echo -e "${BOLD}${BLUE}=====================================================${NC}"
echo ""
echo -e "${CYAN}Project name:${NC}     $PROJECT_NAME"
echo -e "${CYAN}Project location:${NC} $PROJECT_DIR"
echo ""

# Check if directory already exists
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: Directory already exists: $PROJECT_DIR${NC}"
    exit 1
fi

# Create project directory
echo -e "${YELLOW}Creating project directory...${NC}"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Initialize git
echo -e "${YELLOW}Initializing git repository...${NC}"
git init --quiet

# Copy the autonomous agent
echo -e "${YELLOW}Copying autonomous agent...${NC}"
cp -r "$SCRIPT_DIR" .autonomous

# Clean up agent copy
rm -rf .autonomous/.git
rm -rf .autonomous/venv
rm -rf .autonomous/generations
rm -f .autonomous/check-upstream.sh
rm -f .autonomous/cross-check.sh
rm -f .autonomous/new-project.sh
rm -f .autonomous/AUTONOMOUS_AGENT_SETUP_GUIDE.md

# Create project-local venv
echo -e "${YELLOW}Setting up Python environment...${NC}"
cd .autonomous
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt --quiet
deactivate
cd ..

# Create prompts directory
mkdir -p prompts

# Create template app_spec.txt
cat > prompts/app_spec.txt << EOF
<app_spec>
# Project Name: $PROJECT_NAME

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
- Database: [Your choice - PostgreSQL, MongoDB, etc.]

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

# Create .gitignore
cat > .gitignore << 'GITIGNORE'
# Dependencies
node_modules/
.autonomous/venv/

# Build outputs
.next/
dist/
build/
out/

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

# Testing
coverage/

# Agent outputs
generations/
GITIGNORE

# Create README
cat > README.md << EOF
# $PROJECT_NAME

Built with the Autonomous Coding Agent.

## Getting Started

### Running the Autonomous Agent

\`\`\`bash
# Activate the agent's virtual environment
source .autonomous/venv/bin/activate

# Run Phase 1 (initial build)
python3 .autonomous/autonomous_agent_demo.py --project-dir .
\`\`\`

### Subsequent Phases

1. Create \`prompts/phase2_spec.txt\` with Phase 2 requirements
2. Run:
   \`\`\`bash
   python3 .autonomous/autonomous_agent_demo.py --project-dir . --phase 2
   \`\`\`

## Project Structure

\`\`\`
$PROJECT_NAME/
├── .autonomous/         # The autonomous coding agent
├── prompts/             # Project specifications
│   ├── app_spec.txt     # Phase 1 specification
│   └── phase2_spec.txt  # Phase 2 specification (when ready)
├── src/                 # Generated application code
└── features.db          # Feature tracking database
\`\`\`

## Phases

- **Phase 1**: Initial application build based on app_spec.txt
- **Phase 2+**: Enhancements and new features based on phaseN_spec.txt
EOF

# Initial commit
git add .
git commit -m "Initial project setup with autonomous agent" --quiet

echo ""
echo -e "${GREEN}${BOLD}Project created successfully!${NC}"
echo ""
echo -e "${BOLD}${BLUE}=====================================================${NC}"
echo -e "${BOLD}Next Steps:${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo ""
echo -e "1. ${CYAN}cd $PROJECT_DIR${NC}"
echo ""
echo -e "2. ${CYAN}Edit prompts/app_spec.txt${NC} with your project details"
echo ""
echo -e "3. ${CYAN}Run the agent:${NC}"
echo "   source .autonomous/venv/bin/activate"
echo "   python3 .autonomous/autonomous_agent_demo.py --project-dir ."
echo ""
echo -e "${BOLD}${BLUE}=====================================================${NC}"
echo ""
