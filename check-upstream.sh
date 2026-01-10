#!/bin/bash
# check-upstream.sh - Check for upstream changes and provide detailed analysis
# Usage: ./check-upstream.sh [--detailed] [--auto-fetch]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Parse arguments
DETAILED=false
AUTO_FETCH=false
for arg in "$@"; do
    case $arg in
        --detailed) DETAILED=true ;;
        --auto-fetch) AUTO_FETCH=true ;;
    esac
done

echo ""
echo -e "${BOLD}${BLUE}=====================================================${NC}"
echo -e "${BOLD}${BLUE}       UPSTREAM CHANGE DETECTOR & ANALYZER           ${NC}"
echo -e "${BOLD}${BLUE}=====================================================${NC}"
echo ""

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${CYAN}Current branch:${NC} $CURRENT_BRANCH"
echo -e "${CYAN}Custom branch:${NC} soletrader-main"
echo ""

# Fetch upstream
echo -e "${YELLOW}Fetching upstream changes...${NC}"
git fetch upstream --quiet

# Count new commits
NEW_COMMITS=$(git rev-list master..upstream/master --count 2>/dev/null || echo "0")

if [ "$NEW_COMMITS" -eq "0" ]; then
    echo ""
    echo -e "${GREEN}Your fork is up to date with upstream!${NC}"
    echo ""
    echo -e "${BOLD}Last upstream commit:${NC}"
    git log upstream/master -1 --format="  %h - %s (%cr by %an)"
    echo ""
    exit 0
fi

echo ""
echo -e "${RED}${BOLD}Found $NEW_COMMITS new commit(s) in upstream!${NC}"
echo ""

# Show new commits
echo -e "${BOLD}${CYAN}New Commits:${NC}"
echo -e "${CYAN}-----------------------------------------------------${NC}"
git log master..upstream/master --format="  %C(yellow)%h%C(reset) - %s %C(dim)(%cr by %an)%C(reset)"
echo ""

# Show files changed
echo -e "${BOLD}${CYAN}Files Changed:${NC}"
echo -e "${CYAN}-----------------------------------------------------${NC}"
git diff master..upstream/master --stat | head -20
echo ""

# Detailed analysis
if [ "$DETAILED" = true ]; then
    echo -e "${BOLD}${CYAN}Detailed Change Analysis:${NC}"
    echo -e "${CYAN}-----------------------------------------------------${NC}"

    # Get list of changed files
    CHANGED_FILES=$(git diff master..upstream/master --name-only)

    for file in $CHANGED_FILES; do
        echo ""
        echo -e "${BOLD}${YELLOW}File: $file${NC}"

        # Check if this file exists in soletrader-main and differs from master
        if git show soletrader-main:"$file" &>/dev/null 2>&1; then
            CUSTOM_DIFF=$(git diff master..soletrader-main -- "$file" 2>/dev/null | wc -l)
            if [ "$CUSTOM_DIFF" -gt "0" ]; then
                echo -e "  ${RED}WARNING: This file has custom modifications in soletrader-main${NC}"
                echo -e "  ${RED}         Potential merge conflict risk!${NC}"
            else
                echo -e "  ${GREEN}No custom modifications - safe to merge${NC}"
            fi
        fi

        # Show additions/deletions
        ADDS=$(git diff master..upstream/master -- "$file" | grep -c "^+" || true)
        DELS=$(git diff master..upstream/master -- "$file" | grep -c "^-" || true)
        echo -e "  Changes: ${GREEN}+$ADDS${NC} / ${RED}-$DELS${NC} lines"
    done
    echo ""
fi

# Cross-check with custom branch
echo -e "${BOLD}${CYAN}Cross-Check with Your Custom Branch (soletrader-main):${NC}"
echo -e "${CYAN}-----------------------------------------------------${NC}"

# Find files that are different in both upstream AND your custom branch
UPSTREAM_CHANGED=$(git diff master..upstream/master --name-only)
CUSTOM_CHANGED=$(git diff master..soletrader-main --name-only 2>/dev/null || echo "")

CONFLICT_RISK=0
SAFE_FILES=0

for file in $UPSTREAM_CHANGED; do
    if echo "$CUSTOM_CHANGED" | grep -q "^${file}$"; then
        echo -e "  ${RED}CONFLICT RISK:${NC} $file (modified in both)"
        ((CONFLICT_RISK++)) || true
    else
        ((SAFE_FILES++)) || true
    fi
done

echo ""
if [ "$CONFLICT_RISK" -gt "0" ]; then
    echo -e "  ${YELLOW}Files with potential conflicts: ${RED}$CONFLICT_RISK${NC}"
fi
echo -e "  ${GREEN}Files safe to merge: $SAFE_FILES${NC}"
echo ""

# Recommendations
echo -e "${BOLD}${CYAN}Recommended Actions:${NC}"
echo -e "${CYAN}-----------------------------------------------------${NC}"
echo ""

if [ "$CONFLICT_RISK" -gt "0" ]; then
    echo -e "${YELLOW}1. Review conflicting files before merging:${NC}"
    echo "   claude"
    echo "   # Then use the upstream analysis prompt"
    echo ""
    echo -e "${YELLOW}2. Or view the specific conflicts:${NC}"
    for file in $UPSTREAM_CHANGED; do
        if echo "$CUSTOM_CHANGED" | grep -q "^${file}$"; then
            echo "   git diff master..upstream/master -- $file"
        fi
    done
    echo ""
else
    echo -e "${GREEN}No conflicts detected - safe to merge!${NC}"
    echo ""
fi

echo -e "${YELLOW}To merge upstream changes:${NC}"
echo ""
echo "   # Update master branch first"
echo "   git checkout master"
echo "   git pull upstream master"
echo "   git push origin master"
echo ""
echo "   # Then merge into your custom branch"
echo "   git checkout soletrader-main"
echo "   git merge master"
echo "   git push origin soletrader-main"
echo ""

echo -e "${BOLD}${BLUE}=====================================================${NC}"
echo -e "${CYAN}Run with --detailed for file-by-file analysis${NC}"
echo -e "${BOLD}${BLUE}=====================================================${NC}"
echo ""
