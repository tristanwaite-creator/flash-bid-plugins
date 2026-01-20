---
description: "Task orchestration - run, status, pause, add tasks with natural language"
argument-hint: "[run as NAME|status|pause|add task: DESC|next|init|reset ID|complete ID|overview]"
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
| `reset [subtask-id]` | Reset a blocked subtask to pending |
| `complete [subtask-id]` | Manually mark a subtask as completed |
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
2. Generate a task ID (e.g., TASK-001, TASK-002, etc. based on existing count)
3. Add task skeleton to `project-tasks.json`:
   ```json
   {
     "id": "TASK-001",
     "title": "[parsed from description]",
     "description": "[full description]",
     "status": "pending",
     "created_at": "[now]",
     "completed_at": null,
     "subtasks": []
   }
   ```
4. **Use Task tool to spawn the `task-researcher` agent**:
   ```
   Task tool with:
   - subagent_type: "task-orchestrator:task-researcher"
   - prompt: "Break down task TASK-001 into atomic subtasks. The task is: [description]. Read project-tasks.json, analyze affected files, and create validated subtasks."
   ```
5. The agent validates subtasks against poka-yoke rules
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
       "last_heartbeat": "[now]",
       "worker_index": [assigned index 0-N],
       "worker_count": [total active workers]
     }
   }
   ```
4. **Cleanup expired claim_intents**: Scan all subtasks and clear any `claim_intent` where `expires_at < now`
5. Announce: `Worker [NAME] starting...`
6. Begin the orchestrator loop

### Orchestrator Loop

```
WHILE worker.status == "running" AND iteration < 100:
  1. Update heartbeat timestamp

  2. Find candidate subtasks where:
     - status == "pending"
     - claimed_by == null (not claimed by another worker)
     - claim_intent.worker == null OR claim_intent.expires_at < now (no active intent)
     - all dependencies completed

  3. IF no candidate subtasks:
     - Check if other workers still working
     - IF all workers done AND no pending:
       - Output <promise>ALL_TASKS_COMPLETE</promise>
       - BREAK
     - ELSE: Wait and retry (other workers may complete deps)

  4. SELECT subtask using WORKER AFFINITY:
     - Compute affinity score for each candidate:
       score = hash(subtask.id) % worker_count
     - PREFER tasks where score == worker_index (reduces collision probability)
     - If no preferred tasks available, take any candidate

  5. TWO-PHASE CLAIM:
     Phase 1 - Declare Intent:
       - Set subtask.claim_intent.worker = "[NAME]"
       - Set subtask.claim_intent.intent_at = "[now]"
       - Set subtask.claim_intent.expires_at = "[now + 2 seconds]"
       - Save project-tasks.json

     Phase 2 - Wait and Verify (500ms later):
       - Re-read project-tasks.json
       - Check if subtask.claim_intent.worker == "[NAME]" still
       - Check subtask.claimed_by == null still
       - IF verification fails: GOTO step 2 (select different task)
       - IF verification passes: Proceed to full claim

     Phase 3 - Full Claim:
       - Set subtask.claimed_by = "[NAME]"
       - Set subtask.claimed_at = "[now]"
       - Set subtask.status = "in_progress"
       - Clear subtask.claim_intent (set all fields to null)
       - Set worker.current_subtask = subtask.id
       - Save project-tasks.json

  6. EXECUTE the subtask using Task tool:
     ```
     Task tool with:
     - subagent_type: "task-orchestrator:subtask-executor"
     - prompt: "Execute subtask [SUBTASK-ID] as worker [NAME]. [Include full subtask JSON]"
     ```

  7. PROCESS result:
     - Mark subtask completed OR blocked
     - Set subtask.completed_by = "[NAME]"
     - Set subtask.completed_at = "[now]"
     - Add any discoveries as new subtasks
     - Clear worker.current_subtask

  8. LOG to project-activity.md:
     - Include worker name in log entry

  9. Check pause conditions:
     - IF pause_all_requested: Set worker.status = "paused", BREAK
     - IF this worker's pause requested: BREAK

  10. Increment iteration
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

## Action: `reset [subtask-id]`

Reset a blocked or failed subtask to allow retry:

1. Find the subtask by ID in `project-tasks.json`
2. Verify it exists and is in `blocked` or `completed` status
3. Reset fields:
   ```json
   {
     "status": "pending",
     "attempt_count": 0,
     "blocked_reason": null,
     "claimed_by": null,
     "claimed_at": null,
     "completed_by": null,
     "completed_at": null,
     "claim_intent": { "worker": null, "intent_at": null, "expires_at": null }
   }
   ```
4. Log: `🔄 Subtask [ID] reset to pending`
5. Save `project-tasks.json`

**Use case**: When a subtask was blocked due to an issue that has been fixed manually, or to retry after code changes.

---

## Action: `complete [subtask-id]`

Manually mark a subtask as completed (e.g., after manual fix):

1. Find the subtask by ID in `project-tasks.json`
2. Verify it exists
3. Update fields:
   ```json
   {
     "status": "completed",
     "completed_by": "manual",
     "completed_at": "[now]"
   }
   ```
4. Log: `✅ Subtask [ID] manually marked complete`
5. Save `project-tasks.json`

**Use case**: When you've fixed something manually outside the orchestrator and want to mark it done.

---

## Task Schema

```json
{
  "id": "TASK-001",
  "title": "Add user authentication",
  "description": "Implement login, logout, and session management",
  "status": "pending|in_progress|completed",
  "created_at": "2025-01-19T10:00:00Z",
  "completed_at": null,
  "subtasks": []
}
```

## Subtask Schema (updated for multi-worker)

```json
{
  "id": "TASK-001-03",
  "parent_task_id": "TASK-001",
  "title": "Add input validation",
  "description": "Add validation logic for user input fields",
  "status": "pending|in_progress|completed|blocked",
  "estimated_minutes": 10,
  "attempt_count": 0,
  "blocked_reason": null,
  "claimed_by": null,
  "claimed_at": null,
  "completed_by": null,
  "completed_at": null,
  "claim_intent": {
    "worker": null,
    "intent_at": null,
    "expires_at": null
  },
  "dependencies": ["TASK-001-01", "TASK-001-02"],
  "file_path": "src/validators/input.ts",
  "verification": ["npm test -- input.test.ts"],
  "code_context": {
    "file_hash": "abc123def456",
    "snapshot_at": "2025-01-19T10:00:00Z",
    "existing_code": "export function validate(input: string): boolean {\n  // TODO: implement\n  return true;\n}",
    "insert_location": "replace lines 2-3, implement validation logic",
    "pattern_to_follow": "Match existing validator patterns in validators/"
  }
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

Workers coordinate via `project-tasks.json` using **Two-Phase Claiming**:

### Two-Phase Claim Protocol
1. **Intent Declaration**: Worker sets `claim_intent` with 2-second TTL
2. **Verification Wait**: Wait 500ms, re-read file
3. **Claim Validation**: Check intent still belongs to this worker
4. **Full Claim**: If valid, proceed to set `claimed_by`

This prevents race conditions where two workers read the same unclaimed task simultaneously.

### Worker Affinity
Workers hash-distribute tasks to reduce collisions:
```
affinity_score = hash(subtask.id) % worker_count
preferred = (affinity_score == worker_index)
```
Workers prefer their "assigned" tasks, only claiming others when none available.

### Stale Worker Detection
- If worker heartbeat > 5 min old, consider dead
- Dead worker's subtasks return to "pending"
- Clear any expired `claim_intent` on startup

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

2. **Use Task tool to spawn the `overview-builder` agent**:
   ```
   Task tool with:
   - subagent_type: "task-orchestrator:overview-builder"
   - prompt: "Generate project documentation in [MODE] mode. Analyze project-tasks.json, project-activity.md, codebase structure, and git history."
   ```

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
