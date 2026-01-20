---
description: "View the next subtask ready for execution"
argument-hint: "[task-id] (optional - filter by parent task)"
allowed-tools: [Read]
---

# Next Task Command

Show details of the next subtask ready to be executed.

## Usage

```
/next-task           # Show next ready subtask from any task
/next-task TASK-001  # Show next ready subtask in TASK-001 only
```

## Process

1. Read `project-tasks.json`
2. Find subtasks where:
   - `status == "pending"`
   - All dependencies have `status == "completed"`
3. Sort by parent task priority, then by subtask order
4. Display the first ready subtask with full context

---

## Output Format

```
┌──────────────────────────────────────────────────────────────────┐
│                     NEXT READY SUBTASK                            │
├──────────────────────────────────────────────────────────────────┤
│ ID:     TASK-001-03                                              │
│ Parent: TASK-001 "Add user authentication"                       │
│ Title:  Add login API route                                      │
├──────────────────────────────────────────────────────────────────┤
│ File:   api/auth/login.ts                                        │
│ Time:   10 minutes                                               │
│ Deps:   TASK-001-01 (completed), TASK-001-02 (completed)        │
├──────────────────────────────────────────────────────────────────┤
│ CODE CONTEXT                                                      │
│ ┌────────────────────────────────────────────────────────────────┐
│ │ existing_code:                                                  │
│ │   export async function POST(req: Request) {                   │
│ │     // TODO: implement                                         │
│ │   }                                                            │
│ │                                                                │
│ │ insert_location: replace lines 2-3, implement login logic     │
│ │                                                                │
│ │ pattern: Follow existing API route patterns in api/           │
│ └────────────────────────────────────────────────────────────────┘
├──────────────────────────────────────────────────────────────────┤
│ Verification: npx tsc --noEmit && npm test api/auth             │
├──────────────────────────────────────────────────────────────────┤
│ ACTIONS                                                          │
│ • /orchestrate next  - Execute this subtask                     │
│ • /orchestrate run   - Start full execution loop                │
└──────────────────────────────────────────────────────────────────┘
```

---

## If No Subtasks Ready

```
┌──────────────────────────────────────────────────────────────────┐
│                     NO READY SUBTASKS                             │
├──────────────────────────────────────────────────────────────────┤
│ Status:                                                          │
│ • Pending (waiting on deps): 5                                   │
│ • In Progress: 2                                                 │
│ • Blocked: 1                                                     │
│ • Completed: 8                                                   │
├──────────────────────────────────────────────────────────────────┤
│ Waiting on:                                                      │
│ • TASK-001-04 depends on TASK-001-03 (in_progress)              │
│ • TASK-001-05 depends on TASK-001-04 (pending)                  │
├──────────────────────────────────────────────────────────────────┤
│ Blocked subtasks:                                                │
│ • TASK-001-06: TypeScript error after 3 attempts                │
└──────────────────────────────────────────────────────────────────┘
```

---

## If No Tasks Exist

```
No tasks found in project-tasks.json.

To add a task:
  /orchestrate add task: [description]

Or run /orchestrate init to set up project-tasks.json
```

---

## If Tasks Not Broken Down

```
Task TASK-001 has not been broken down into subtasks yet.

Run: /breakdown TASK-001
```
