#!/bin/bash
# Task Orchestrator - Project Initialization Script
# Creates project-tasks.json and project-activity.md in the current directory

set -e

PROJECT_DIR="${1:-.}"
TASKS_FILE="$PROJECT_DIR/project-tasks.json"
ACTIVITY_FILE="$PROJECT_DIR/project-activity.md"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "Task Orchestrator - Project Initialization"
echo "==========================================="

# Create project-tasks.json if it doesn't exist
if [ -f "$TASKS_FILE" ]; then
    echo -e "${YELLOW}project-tasks.json already exists, skipping...${NC}"
else
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    # Detect project name from package.json or directory name
    if [ -f "$PROJECT_DIR/package.json" ]; then
        PROJECT_NAME=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$PROJECT_DIR/package.json" | head -1 | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    fi
    PROJECT_NAME="${PROJECT_NAME:-$(basename "$(cd "$PROJECT_DIR" && pwd)")}"

    cat > "$TASKS_FILE" << EOF
{
  "project": "$PROJECT_NAME",
  "description": "",
  "created_at": "$TIMESTAMP",
  "orchestrator_state": {
    "status": "idle",
    "started_at": null,
    "pause_all_requested": false
  },
  "workers": {},
  "tasks": []
}
EOF
    echo -e "${GREEN}Created project-tasks.json${NC}"
fi

# Create project-activity.md if it doesn't exist
if [ -f "$ACTIVITY_FILE" ]; then
    echo -e "${YELLOW}project-activity.md already exists, skipping...${NC}"
else
    DATE=$(date +"%Y-%m-%d")
    TIME=$(date +"%H:%M:%S")
    cat > "$ACTIVITY_FILE" << EOF
# Project Activity Log

## $DATE

### $TIME - Project Initialized
- **Status**: Ready for workers
- **Pending tasks**: 0
- **Active workers**: none

---
EOF
    echo -e "${GREEN}Created project-activity.md${NC}"
fi

echo ""
echo "Initialization complete!"
echo ""
echo -e "${CYAN}Multi-Worker Usage:${NC}"
echo "  Terminal 1: /orchestrate run as alpha"
echo "  Terminal 2: /orchestrate run as beta"
echo "  Terminal 3: /orchestrate run as gamma"
echo ""
echo "Other commands:"
echo "  /orchestrate add task: [description]  - Add a new task"
echo "  /orchestrate status                   - Show all workers & progress"
echo "  /orchestrate pause                    - Pause this worker"
echo "  /orchestrate pause all                - Pause all workers"
echo ""
