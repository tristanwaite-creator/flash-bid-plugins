# Subtask Schema Reference

This is the **canonical schema definition** for subtasks in the Task Orchestrator. All other files reference this schema.

## Complete Schema

```json
{
  "id": "TASK-001-01",
  "parent_task_id": "TASK-001",
  "title": "Brief action description",
  "description": "Detailed description of what to do",
  "file_path": "path/to/single/file.ts",
  "estimated_minutes": 10,
  "dependencies": ["TASK-001-00"],
  "verification": ["npx tsc --noEmit", "npm test -- --grep 'TestName'"],
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
    "existing_code": "actual code snippet here (20+ chars)",
    "insert_location": "after line 44, inside XYZ block",
    "pattern_to_follow": "description of pattern to match"
  }
}
```

## Field Definitions

### Core Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique identifier, format: `PARENT-ID-NN` |
| `parent_task_id` | string | Yes | ID of the parent task |
| `title` | string | Yes | Brief action description (5-10 words) |
| `description` | string | Yes | Detailed description of the change |
| `file_path` | string | Yes | **Exactly ONE file** - no commas, no multiple paths |
| `estimated_minutes` | number | Yes | **Must be 5-15** (poka-yoke rule) |
| `dependencies` | string[] | Yes | Array of subtask IDs that must complete first |
| `verification` | string[] | Yes | **Array** of verification commands (never a string) |
| `status` | string | Yes | One of: `pending`, `in_progress`, `completed`, `blocked` |
| `attempt_count` | number | Yes | Number of execution attempts (max 3) |
| `blocked_reason` | string\|null | Yes | Reason if status is `blocked`, otherwise null |

### Multi-Worker Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `claimed_by` | string\|null | Yes | Worker name that claimed this subtask |
| `claimed_at` | string\|null | Yes | ISO timestamp when claimed |
| `completed_by` | string\|null | Yes | Worker name that completed it |
| `completed_at` | string\|null | Yes | ISO timestamp when completed |

**IMPORTANT**: Always initialize these as `null` when creating new subtasks.

### Claim Intent (Two-Phase Claiming)

| Field | Type | Description |
|-------|------|-------------|
| `claim_intent.worker` | string\|null | Worker declaring intent to claim |
| `claim_intent.intent_at` | string\|null | ISO timestamp of intent declaration |
| `claim_intent.expires_at` | string\|null | ISO timestamp when intent expires (2s TTL) |

This enables atomic task claiming across multiple workers:
1. Worker declares intent (sets `claim_intent` with 2s TTL)
2. Waits 500ms
3. Re-reads file, checks if their intent is still oldest/valid
4. If yes: proceeds to full claim; if no: selects different task

### Code Context (Poka-yoke)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `code_context.file_hash` | string | Yes | First 12 chars of sha256 hash |
| `code_context.snapshot_at` | string | Yes | ISO timestamp when context captured |
| `code_context.existing_code` | string | Yes | **20+ characters** of actual code |
| `code_context.insert_location` | string | Yes | Must match pattern: `line \d+\|after \|before \|end of \|start of \|replace` |
| `code_context.pattern_to_follow` | string | Yes | Description of code pattern to match |

## Validation Rules (Poka-yoke)

Every subtask MUST pass ALL five rules:

| Rule | Field | Requirement |
|------|-------|-------------|
| singleFile | `file_path` | Exactly ONE file path, no commas |
| timeBoxed | `estimated_minutes` | Between 5 and 15 (inclusive) |
| verifiable | `verification` | Non-empty array of commands |
| hasCodeContext | `code_context.existing_code` | 20+ characters of actual code |
| hasLocation | `code_context.insert_location` | Matches location pattern regex |

## Status Transitions

```
pending → in_progress (when claimed)
in_progress → completed (success)
in_progress → blocked (failure after 3 attempts)
in_progress → pending (worker died, reclaimed)
blocked → pending (manual unblock)
```

## Default Values for New Subtasks

When creating a subtask, always set:
```json
{
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
  }
}
```
