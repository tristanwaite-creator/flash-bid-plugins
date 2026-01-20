---
description: "Task orchestration - run, status, pause, add tasks with natural language"
argument-hint: "[run as NAME|status|pause|add task: desc|next|init]"
allowed-tools: [Task, Read, Write, Edit, Glob, Grep, Bash, TodoWrite]
---

# Task Orchestrator Command

You are the task orchestrator for this project. Parse the user's input and execute the appropriate action.

## Command Parsing

| Input Pattern | Action |
|---------------|--------|
| `run as [NAME]` | Start loop with worker name (e.g., `run as alpha`) |
| `run` or `start` | Start loop with auto-generated name |
| `status` | Show progress dashboard with active workers |
| `pause` | Stop this worker after current subtask |
| `pause all` | Signal all workers to pause |
| `add task: [description]` | Create and breakdown a new task |
| `next` | Execute single next subtask |
| `init` | Initialize project-tasks.json |
| `overview` | Generate full project documentation |
| `overview update` | Incremental documentation update |
| `overview architecture` | Generate only ARCHITECTURE.md |
| `overview files` | Generate only FILE-MAP.md |
| `overview history` | Generate only CHANGELOG.md |
| (no argument) | Show status |

## Multi-Worker Architecture

Multiple terminals can run orchestrators simultaneously. Each worker:
- Has a unique name (e.g., `alpha`, `beta`, `gamma`)
- Claims subtasks before executing (prevents conflicts)
- Logs its name with every action
- Only works on subtasks it has claimed

```
Terminal 1                    Terminal 2                    Terminal 3
─────────────────────────────────────────────────────────────────────────
/orchestrate run as alpha     /orchestrate run as beta      /orchestrate run as gamma
    │                             │                             │
    ▼                             ▼                             ▼
Claims TASK-001-01            Claims TASK-001-02            Claims TASK-002-01
Working on auth...            Working on API...             Working on UI...
```

## Configuration

- **Tasks file**: `project-tasks.json` (in project root)
- **Activity log**: `project-activity.md` (in project root)
- **Max concurrent workers**: unlimited (self-coordinating)
- **Max iterations per worker**: 100

---

## Action: `init`

Create `project-tasks.json` if it doesn't exist:

```json
{
  "project": "[detect from package.json or directory name]",
  "description": "",
  "orchestrator_state": {
    "status": "idle",
    "started_at": null,
    "pause_all_requested": false
  },
  "workers": {},
  "tasks": []
}
```

**Workers object** tracks active workers:
```json
"workers": {
  "alpha": {
    "status": "running",
    "started_at": "2024-01-20T10:00:00Z",
    "current_subtask": "TASK-001-03",
    "iteration": 5,
    "last_heartbeat": "2024-01-20T10:05:00Z"
  },
  "beta": {
    "status": "running",
    "started_at": "2024-01-20T10:01:00Z",
    "current_subtask": "TASK-002-01",
    "iteration": 3,
    "last_heartbeat": "2024-01-20T10:04:30Z"
  }
}
```

Also create `project-activity.md` with header.

---

## Action: `status`

1. Read `project-tasks.json`
2. Count tasks by status
3. Count subtasks by status
4. Show active workers
5. Display dashboard:

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        ORCHESTRATOR STATUS                                │
├──────────────────────────────────────────────────────────────────────────┤
│ ACTIVE WORKERS                                                            │
│ ┌────────┬─────────┬──────────────┬───────────┐                          │
│ │ Name   │ Status  │ Working On   │ Iteration │                          │
│ ├────────┼─────────┼──────────────┼───────────┤                          │
│ │ alpha  │ running │ TASK-001-03  │ 5/100     │                          │
│ │ beta   │ running │ TASK-002-01  │ 3/100     │                          │
│ │ gamma  │ paused  │ -            │ 12/100    │                          │
│ └────────┴─────────┴──────────────┴───────────┘                          │
├──────────────────────────────────────────────────────────────────────────┤
│ TASKS                                                                     │
│ Total: 5    Not Started: 1    In Progress: 3    Completed: 1             │
├──────────────────────────────────────────────────────────────────────────┤
│ SUBTASKS                                                                  │
│ Total: 15   Pending: 8   Claimed: 2   Completed: 4   Blocked: 1          │
├──────────────────────────────────────────────────────────────────────────┤
│ UNCLAIMED READY (available for workers)                                   │
│ • TASK-001-04: Add validation to user input                              │
│ • TASK-003-01: Create database migration                                 │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Action: `add task: [description]`

1. Parse the description to identify:
   - Likely category (extraction, ui, api, etc.)
   - Files that might be affected
2. Generate a task ID (e.g., TASK-001)
3. Add to `project-tasks.json`
4. Spawn the `task-researcher` agent to break it down into subtasks
5. Validate subtasks against poka-yoke rules
6. Report completion with subtask count

---

## Action: `run as [NAME]` or `run`

**This activates a persistent loop like Ralph Wiggum!**

If no name provided, generate one: `worker-[random-4-chars]`

### Startup Sequence

1. Read `project-tasks.json`
2. Check if worker name already active → error if so
3. Register this worker:
   ```json
   "workers": {
     "[NAME]": {
       "status": "running",
       "started_at": "[now]",
       "current_subtask": null,
       "iteration": 0,
       "last_heartbeat": "[now]"
     }
   }
   ```
4. Announce: `🚀 Worker [NAME] starting...`
5. Begin the orchestrator loop

### Orchestrator Loop

```
WHILE worker.status == "running" AND iteration < 100:
  1. Update heartbeat timestamp

  2. Find subtasks where:
     - status == "pending"
     - claimed_by == null (not claimed by another worker)
     - all dependencies completed

  3. IF no ready subtasks:
     - Check if other workers still working
     - IF all workers done AND no pending:
       - Output <promise>ALL_TASKS_COMPLETE</promise>
       - BREAK
     - ELSE: Wait and retry (other workers may complete deps)

  4. CLAIM a subtask:
     - Set subtask.claimed_by = "[NAME]"
     - Set subtask.claimed_at = "[now]"
     - Set subtask.status = "in_progress"
     - Set worker.current_subtask = subtask.id
     - Save project-tasks.json

  5. EXECUTE the subtask:
     - Use subtask-executor agent
     - Pass full subtask context

  6. PROCESS result:
     - Mark subtask completed OR blocked
     - Set subtask.completed_by = "[NAME]"
     - Add any discoveries as new subtasks
     - Clear worker.current_subtask

  7. LOG to project-activity.md:
     - Include worker name in log entry

  8. Check pause conditions:
     - IF pause_all_requested: Set worker.status = "paused", BREAK
     - IF this worker's pause requested: BREAK

  9. Increment iteration
```

### Completion

When this worker has no more work AND no other workers active:
```
<promise>ALL_TASKS_COMPLETE</promise>
```

---

## Action: `pause`

1. Set this worker's status to "paused" in `workers` object
2. Clear current_subtask
3. Log: `⏸️ Worker [NAME] paused at iteration [N]`
4. Release any claimed-but-not-started subtasks

## Action: `pause all`

1. Set `orchestrator_state.pause_all_requested = true`
2. All workers will pause after their current subtask
3. Log: `⏸️ Pause requested for all workers`

---

## Action: `next`

1. Find the next ready unclaimed subtask
2. Claim it temporarily (no worker registration)
3. Execute it directly
4. Update status
5. Do NOT continue the loop

---

## Subtask Schema (updated for multi-worker)

```json
{
  "id": "TASK-001-03",
  "title": "Add input validation",
  "status": "pending|in_progress|completed|blocked",
  "claimed_by": null,
  "claimed_at": null,
  "completed_by": null,
  "completed_at": null,
  "dependencies": ["TASK-001-01", "TASK-001-02"],
  "file_path": "src/validators/input.ts",
  "code_context": { ... },
  "verification": "npm test -- input.test.ts"
}
```

---

## Activity Logging (with worker names)

```markdown
### 2024-01-20 10:05:23 - Subtask Completed [alpha]
- **Subtask**: TASK-001-03 - Add input validation
- **Worker**: alpha
- **Duration**: 3m 42s
- **Files modified**: src/validators/input.ts

### 2024-01-20 10:04:15 - Subtask Started [beta]
- **Subtask**: TASK-002-01 - Create API endpoint
- **Worker**: beta
```

---

## Conflict Prevention

Workers coordinate via `project-tasks.json`:
- **Atomic claims**: Read → Check unclaimed → Write claim (with timestamp)
- **Stale detection**: If worker heartbeat > 5 min old, consider dead
- **Reclaim**: Dead worker's subtasks return to "pending"

---

## Error Handling

- If `project-tasks.json` doesn't exist: Prompt user to run `init`
- If worker name taken: Error with list of active workers
- If no tasks: Show helpful message about adding tasks
- If all subtasks blocked: Report and pause
- If max iterations reached: Pause this worker with warning

---

## Action: `overview [subcommand]`

Generate comprehensive project documentation by analyzing project state, activity logs, codebase structure, and git history.

### Subcommands

| Subcommand | Description |
|------------|-------------|
| (none) | Generate all 5 documentation files |
| `update` | Incremental update - only changed sections |
| `architecture` | Generate only ARCHITECTURE.md |
| `files` | Generate only FILE-MAP.md |
| `history` | Generate only CHANGELOG.md |

### Execution

1. Parse subcommand to determine mode:
   - No subcommand → `full`
   - `update` → `update`
   - `architecture` → `architecture`
   - `files` → `files`
   - `history` → `history`

2. Spawn the `overview-builder` agent with the mode parameter

3. The agent will:
   - Read `project-tasks.json` for task data
   - Parse `project-activity.md` for timeline
   - Analyze codebase structure via glob/grep
   - Check git history for changes
   - Generate documentation files

### Generated Files

All documentation is created in the project root:

```
project/
├── project-tasks.json      # (existing)
├── project-activity.md     # (existing)
├── PROJECT-OVERVIEW.md     # High-level summary
├── ARCHITECTURE.md         # Technical architecture
├── FILE-MAP.md             # File structure with annotations
├── CHANGELOG.md            # Change history
└── DEPENDENCIES.md         # Dependency tracking
```

### Example Usage

```
/orchestrate overview           # Generate all docs
/orchestrate overview update    # Update after changes
/orchestrate overview files     # Just regenerate file map
```

### Output

After generation:
```
📚 Documentation Updated

Generated:
├── PROJECT-OVERVIEW.md  (2.3 KB)
├── ARCHITECTURE.md      (4.1 KB)
├── FILE-MAP.md          (3.8 KB)
├── CHANGELOG.md         (1.5 KB)
└── DEPENDENCIES.md      (1.2 KB)

Last update: 2024-01-20 10:30:00
```
