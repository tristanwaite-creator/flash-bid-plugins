# Task Orchestrator Plugin

A multi-worker task management system implementing patterns from Anthropic's "Building Effective Agents" article.

## Features

- **Multi-Worker Parallel Execution** - Run multiple terminals simultaneously
- **Named Workers** - Each worker has identity (alpha, beta, gamma...)
- **Task Claiming** - Workers claim subtasks to prevent conflicts
- **Persistent Loop** - Stop hook re-prompts until all tasks complete
- **Web Research** - Workers can search and fetch documentation
- **Atomic Decomposition** - Break tasks into 5-15 minute subtasks
- **Poka-yoke Validation** - 5 strict rules ensure subtask quality
- **3-Strike Retry** - Robust error handling with escalation
- **Activity Logging** - Full audit trail with worker attribution

## Multi-Worker Architecture

```
Terminal 1                    Terminal 2                    Terminal 3
─────────────────────────────────────────────────────────────────────────
/orchestrate run as alpha     /orchestrate run as beta      /orchestrate run as gamma
    │                             │                             │
    ▼                             ▼                             ▼
Claims TASK-001-01            Claims TASK-001-02            Claims TASK-002-01
Working on auth...            Working on API...             Working on UI...
    │                             │                             │
    ▼                             ▼                             ▼
✓ Complete                    ✓ Complete                    ✓ Complete
Claims TASK-001-03            Claims TASK-002-02            Claims TASK-003-01
    ...                           ...                           ...
```

Workers coordinate via `project-tasks.json`:
- Atomic task claiming prevents duplicates
- Heartbeat tracking detects stale workers
- Activity log shows which worker did what

## Commands

| Command | Description |
|---------|-------------|
| `/orchestrate run as [name]` | Start worker with specific name |
| `/orchestrate run` | Start worker with auto-generated name |
| `/orchestrate status` | Show all workers and progress |
| `/orchestrate pause` | Pause this worker |
| `/orchestrate pause all` | Signal all workers to stop |
| `/orchestrate add task: [desc]` | Add and breakdown a new task |
| `/orchestrate next` | Execute single next subtask |
| `/orchestrate init` | Initialize project-tasks.json |
| `/orchestrate reset [id]` | Reset a blocked subtask to pending |
| `/orchestrate complete [id]` | Manually mark subtask as completed |
| `/orchestrate overview` | Generate project documentation |
| `/breakdown [task-id]` | Manually breakdown a task |
| `/next-task` | View next ready subtask (read-only) |

## Quick Start

```bash
# Terminal 1
cd your-project
/orchestrate init
/orchestrate add task: implement user authentication
/orchestrate run as alpha

# Terminal 2 (same project)
/orchestrate run as beta

# Terminal 3 (same project)
/orchestrate run as gamma
```

## How the Loop Works

1. Worker starts → Registers in `workers` object
2. Claims an unclaimed subtask
3. Executes subtask (with web research if needed)
4. Marks complete, logs activity
5. Stop hook fires → Checks for more work
6. If more work: Loop continues
7. If all done: `<promise>ALL_TASKS_COMPLETE</promise>`

## Project Files

| File | Purpose |
|------|---------|
| `project-tasks.json` | Task state, worker registry, subtasks |
| `project-activity.md` | Audit log with worker attribution |
| `PROJECT-OVERVIEW.md` | Generated high-level documentation |
| `ARCHITECTURE.md` | Generated architecture diagrams |
| `FILE-MAP.md` | Generated file structure map |
| `CHANGELOG.md` | Generated change history |
| `DEPENDENCIES.md` | Generated dependency tracking |

## Subtask Schema

> **Canonical reference**: See `schema/subtask-schema.md` for complete field definitions.

```json
{
  "id": "TASK-001-03",
  "title": "Add input validation",
  "status": "pending",
  "claimed_by": null,
  "claimed_at": null,
  "completed_by": null,
  "completed_at": null,
  "claim_intent": {
    "worker": null,
    "intent_at": null,
    "expires_at": null
  },
  "dependencies": ["TASK-001-01"],
  "file_path": "src/validators.ts",
  "verification": ["npm test"],
  "code_context": {
    "existing_code": "...",
    "insert_location": "after line 25"
  }
}
```

## Validation Rules (Poka-yoke)

| Rule | Requirement |
|------|-------------|
| singleFile | Exactly ONE file_path |
| timeBoxed | 5-15 minutes estimated |
| verifiable | Has verification command |
| hasCodeContext | Code snippet >20 chars |
| hasLocation | Specific insert location |

## License

MIT
