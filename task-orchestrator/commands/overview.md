---
description: "Generate comprehensive project documentation from task history, activity logs, and codebase analysis"
argument-hint: "[update|architecture|files|history] (optional)"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, TodoWrite]
---

# Overview Builder Command

Generate comprehensive project documentation by analyzing:
- `project-tasks.json` - Task history and structure
- `project-activity.md` - Worker activity and timeline
- Codebase structure and dependencies
- Git history

## Command Parsing

| Input | Mode | Output |
|-------|------|--------|
| (none) | `full` | All 5 documentation files |
| `update` | `update` | Incremental update only |
| `architecture` | `architecture` | Only ARCHITECTURE.md |
| `files` | `files` | Only FILE-MAP.md |
| `history` | `history` | Only CHANGELOG.md |

## Execution

Based on argument "$ARGUMENTS":

1. **Read project state**:
   - `project-tasks.json` for task data
   - `project-activity.md` for timeline

2. **Analyze codebase**:
   - Glob for source files
   - Map directory structure
   - Identify dependencies via imports

3. **Check git history**:
   - Recent commits
   - Files changed

4. **Generate documentation** in project root:
   - `PROJECT-OVERVIEW.md` - Summary, stats, components
   - `ARCHITECTURE.md` - System flow, dependencies, patterns
   - `FILE-MAP.md` - Annotated file tree
   - `CHANGELOG.md` - Change history from activity
   - `DEPENDENCIES.md` - Package and module deps

## Output Format

```
📚 Documentation Updated

Generated:
├── PROJECT-OVERVIEW.md  (size)
├── ARCHITECTURE.md      (size)
├── FILE-MAP.md          (size)
├── CHANGELOG.md         (size)
└── DEPENDENCIES.md      (size)

Last update: [timestamp]
```
