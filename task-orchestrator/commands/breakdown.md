---
description: "Break down a task into atomic subtasks with poka-yoke validation"
argument-hint: "[task-id]"
allowed-tools: [Task, Read, Write, Glob, Grep, Bash]
---

# Breakdown Command

Break down a specific task into atomic, executable subtasks.

## Usage

```
/breakdown TASK-001
/breakdown EXT-001
```

## Process

**Use the Task tool to spawn the `task-researcher` agent** with the task ID as context. The agent will:

1. **Read the task** from `project-tasks.json`
2. **Analyze files** that will be modified (using Glob/Grep/Read)
3. **Research** unfamiliar APIs/patterns (using WebSearch/WebFetch)
4. **Generate subtasks** following atomic decomposition principles
5. **Validate** each subtask against poka-yoke rules
6. **Regenerate** any that fail validation (max 3 attempts)
7. **Write** subtasks back to `project-tasks.json`
8. **Log** breakdown to `project-activity.md`

### Agent Invocation

```
Use Task tool with:
- subagent_type: "task-orchestrator:task-researcher"
- prompt: "Break down task [TASK-ID] into atomic subtasks. Read the task from project-tasks.json, analyze affected files, and create validated subtasks."
```

---

## Poka-Yoke Validation Rules

Every subtask MUST pass ALL five rules:

| Rule | Requirement | Example Pass | Example Fail |
|------|-------------|--------------|--------------|
| singleFile | Exactly ONE file_path | `lib/types.ts` | `lib/types.ts, lib/index.ts` |
| timeBoxed | 5-15 minutes | `10` | `3` or `25` |
| verifiable | Has verification cmd | `["npx tsc --noEmit"]` | `[]` |
| hasCodeContext | Code >20 chars | Actual code snippet | `"line 42"` |
| hasLocation | Specific location | `"after line 44"` | `"somewhere"` |

---

## Subtask Schema

```json
{
  "id": "TASK-001-01",
  "parent_task_id": "TASK-001",
  "title": "Add UserType enum",
  "description": "Add enum for user types: ADMIN, USER, GUEST",
  "file_path": "lib/types.ts",
  "estimated_minutes": 8,
  "dependencies": [],
  "verification": ["npx tsc --noEmit"],
  "status": "pending",
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

  "code_context": {
    "file_hash": "abc123def456",
    "snapshot_at": "2025-01-19T10:00:00Z",
    "existing_code": "export type Role = 'admin' | 'user';",
    "insert_location": "after Role type, around line 25",
    "pattern_to_follow": "Same format as Role type"
  }
}
```

**IMPORTANT**: When creating subtasks, ALWAYS initialize multi-worker fields:
- `claimed_by`, `claimed_at`, `completed_by`, `completed_at` → `null`
- `claim_intent` → `{ "worker": null, "intent_at": null, "expires_at": null }`

---

## Breakdown Strategy

### By Operation Type
```
"Add user authentication" (60 mins) →
├── "Add User interface" (10 mins) - types.ts
├── "Add auth utility functions" (12 mins) - auth.ts
├── "Add login API route" (10 mins) - api/login.ts
├── "Add session middleware" (10 mins) - middleware.ts
└── "Add auth context" (10 mins) - context.tsx
```

### By File Section
```
"Update types.ts" (30 mins) →
├── "Add UserType enum (lines 1-15)" (8 mins)
├── "Add User interface (lines 16-30)" (10 mins)
└── "Export new types (lines 31-40)" (7 mins)
```

---

## Code Context Capture

For each file in the task, capture:

1. **Read the file** to get current content
2. **Compute hash** (first 12 chars of sha256)
3. **Extract relevant code** at insertion point
4. **Determine exact location** (line numbers, after/before markers)

```bash
# Example hash computation
cat lib/types.ts | sha256sum | cut -c1-12
```

---

## Validation Output

Show validation results for each subtask:

```
Validating TASK-001-01...
  [PASS] singleFile: lib/types.ts
  [PASS] timeBoxed: 8 minutes
  [PASS] verifiable: npx tsc --noEmit
  [PASS] hasCodeContext: 45 chars
  [PASS] hasLocation: "after line 25"
  Result: VALID

Validating TASK-001-02...
  [PASS] singleFile: lib/auth.ts
  [FAIL] timeBoxed: 25 minutes (max 15)
  Result: INVALID - regenerating...
```

---

## Regeneration

When a subtask fails validation:

1. Identify the failing rule
2. Split the subtask if too large
3. Add more context if too vague
4. Re-validate
5. Max 3 regeneration attempts

---

## Output

After successful breakdown:

```
Breakdown complete: TASK-001
├── Subtasks created: 5
├── Estimated time: 48 minutes
├── All validations: PASSED
└── Ready for: /orchestrate run
```
