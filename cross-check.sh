#!/bin/bash
# cross-check.sh - Detailed cross-checking of upstream changes with your customizations
# Usage: ./cross-check.sh [file] [--report] [--interactive]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Parse arguments
SPECIFIC_FILE=""
GENERATE_REPORT=false
INTERACTIVE=false

for arg in "$@"; do
    case $arg in
        --report) GENERATE_REPORT=true ;;
        --interactive) INTERACTIVE=true ;;
        -*) ;; # Skip other flags
        *) SPECIFIC_FILE="$arg" ;;
    esac
done

print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}=====================================================${NC}"
    echo -e "${BOLD}${BLUE}          UPSTREAM CROSS-CHECK ANALYZER              ${NC}"
    echo -e "${BOLD}${BLUE}=====================================================${NC}"
    echo ""
}

# Check if upstream remote exists
if ! git remote | grep -q "^upstream$"; then
    echo -e "${YELLOW}Setting up upstream remote...${NC}"
    git remote add upstream https://github.com/leonvanzyl/autonomous-coding.git
fi

# Ensure we have latest upstream
git fetch upstream --quiet 2>/dev/null || true

# Function to analyze a single file
analyze_file() {
    local file="$1"
    echo ""
    echo -e "${BOLD}${MAGENTA}Analyzing: $file${NC}"
    echo -e "${DIM}───────────────────────────────────────────────────${NC}"

    # Check if file exists in each location
    local in_upstream=$(git show upstream/master:"$file" &>/dev/null && echo "yes" || echo "no")
    local in_local=$(git show HEAD:"$file" &>/dev/null && echo "yes" || echo "no")

    echo -e "  ${CYAN}Exists in upstream/master:${NC}  $in_upstream"
    echo -e "  ${CYAN}Exists locally:${NC}             $in_local"
    echo ""

    # Calculate differences
    local upstream_changes=0
    local local_changes=0

    if [ "$in_upstream" = "yes" ]; then
        upstream_changes=$(git diff HEAD..upstream/master -- "$file" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$upstream_changes" -gt "0" ]; then
            echo -e "  ${YELLOW}Upstream has changes:${NC} $upstream_changes diff lines"

            # Show summary of what changed
            local adds=$(git diff HEAD..upstream/master -- "$file" | grep -c "^+" 2>/dev/null || echo "0")
            local dels=$(git diff HEAD..upstream/master -- "$file" | grep -c "^-" 2>/dev/null || echo "0")
            echo -e "  ${GREEN}+$adds additions${NC} / ${RED}-$dels deletions${NC}"
        else
            echo -e "  ${GREEN}No upstream changes to this file${NC}"
        fi
    fi

    if [ "$in_local" = "yes" ]; then
        local_changes=$(git diff upstream/master..HEAD -- "$file" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$local_changes" -gt "0" ]; then
            echo -e "  ${YELLOW}Your local modifications:${NC} $local_changes diff lines"

            # Conflict assessment
            if [ "$upstream_changes" -gt "0" ]; then
                echo ""
                echo -e "  ${RED}${BOLD}POTENTIAL CONFLICT${NC}"
                echo -e "  ${RED}Both upstream and you modified this file!${NC}"
                echo ""
                echo -e "  ${CYAN}View upstream changes:${NC}"
                echo -e "    git diff HEAD..upstream/master -- $file"
                echo ""
                echo -e "  ${CYAN}View your changes:${NC}"
                echo -e "    git diff upstream/master..HEAD -- $file"
            fi
        else
            echo -e "  ${GREEN}No local modifications - upstream changes are safe to merge${NC}"
        fi
    fi
}

# Function to generate a full report
generate_report() {
    local report_file="upstream_crosscheck_report_$(date +%Y%m%d_%H%M%S).md"

    echo "# Upstream Cross-Check Report" > "$report_file"
    echo "" >> "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    echo "## Summary" >> "$report_file"
    echo "" >> "$report_file"

    # Get all changed files
    local upstream_files=$(git diff HEAD..upstream/master --name-only 2>/dev/null)

    local conflict_files=""
    local safe_files=""

    for file in $upstream_files; do
        local_changes=$(git diff upstream/master..HEAD -- "$file" 2>/dev/null | wc -l)
        if [ "$local_changes" -gt "0" ]; then
            conflict_files="$conflict_files $file"
        else
            safe_files="$safe_files $file"
        fi
    done

    # Count
    local conflict_count=$(echo $conflict_files | wc -w | tr -d ' ')
    local safe_count=$(echo $safe_files | wc -w | tr -d ' ')

    echo "- **Files with potential conflicts:** $conflict_count" >> "$report_file"
    echo "- **Files safe to merge:** $safe_count" >> "$report_file"
    echo "" >> "$report_file"

    if [ "$conflict_count" -gt "0" ]; then
        echo "## Files Requiring Review" >> "$report_file"
        echo "" >> "$report_file"
        echo "These files have been modified in both upstream AND locally:" >> "$report_file"
        echo "" >> "$report_file"
        for file in $conflict_files; do
            echo "### \`$file\`" >> "$report_file"
            echo "" >> "$report_file"
            echo "**Upstream changes:**" >> "$report_file"
            echo "\`\`\`diff" >> "$report_file"
            git diff HEAD..upstream/master -- "$file" 2>/dev/null | head -50 >> "$report_file"
            echo "\`\`\`" >> "$report_file"
            echo "" >> "$report_file"
            echo "**Your local changes:**" >> "$report_file"
            echo "\`\`\`diff" >> "$report_file"
            git diff upstream/master..HEAD -- "$file" 2>/dev/null | head -50 >> "$report_file"
            echo "\`\`\`" >> "$report_file"
            echo "" >> "$report_file"
        done
    fi

    if [ "$safe_count" -gt "0" ]; then
        echo "## Safe to Merge" >> "$report_file"
        echo "" >> "$report_file"
        echo "These upstream changes don't conflict with your customizations:" >> "$report_file"
        echo "" >> "$report_file"
        for file in $safe_files; do
            echo "- \`$file\`" >> "$report_file"
        done
        echo "" >> "$report_file"
    fi

    echo "## Recommended Merge Commands" >> "$report_file"
    echo "" >> "$report_file"
    echo "\`\`\`bash" >> "$report_file"
    echo "# Merge upstream changes" >> "$report_file"
    echo "git fetch upstream" >> "$report_file"
    echo "git merge upstream/master" >> "$report_file"
    echo "" >> "$report_file"
    echo "# If conflicts occur, resolve them, then:" >> "$report_file"
    echo "git add ." >> "$report_file"
    echo "git commit -m \"Merge upstream changes\"" >> "$report_file"
    echo "git push origin master" >> "$report_file"
    echo "\`\`\`" >> "$report_file"

    echo -e "${GREEN}Report generated: $report_file${NC}"
}

# Main execution
print_header

if [ -n "$SPECIFIC_FILE" ]; then
    # Analyze specific file
    analyze_file "$SPECIFIC_FILE"
else
    # Analyze all changed files
    echo -e "${CYAN}Fetching upstream changes...${NC}"
    git fetch upstream --quiet

    NEW_COMMITS=$(git rev-list HEAD..upstream/master --count 2>/dev/null || echo "0")

    if [ "$NEW_COMMITS" -eq "0" ]; then
        echo -e "${GREEN}No new upstream changes detected.${NC}"
        echo ""
        exit 0
    fi

    echo -e "${YELLOW}Found $NEW_COMMITS new commit(s) in upstream${NC}"
    echo ""

    # Get changed files
    UPSTREAM_FILES=$(git diff HEAD..upstream/master --name-only)

    echo -e "${BOLD}${CYAN}Analyzing all changed files...${NC}"

    for file in $UPSTREAM_FILES; do
        analyze_file "$file"
    done
fi

# Generate report if requested
if [ "$GENERATE_REPORT" = true ]; then
    echo ""
    echo -e "${CYAN}Generating detailed report...${NC}"
    generate_report
fi

echo ""
echo -e "${BOLD}${BLUE}=====================================================${NC}"
echo -e "${DIM}Usage:${NC}"
echo -e "  ${CYAN}./cross-check.sh${NC}              - Analyze all upstream changes"
echo -e "  ${CYAN}./cross-check.sh <file>${NC}       - Analyze specific file"
echo -e "  ${CYAN}./cross-check.sh --report${NC}     - Generate markdown report"
echo -e "${BOLD}${BLUE}=====================================================${NC}"
echo ""
