---
name: atomic-decomposition
description: Use this skill when breaking down tasks into atomic subtasks, validating subtask structure, or understanding poka-yoke validation rules. Triggers on "break down task", "atomic subtask", "poka-yoke", "subtask validation", "task decomposition".
version: 1.0.0
---

# Atomic Decomposition

Break tasks into atomic, executable subtasks using poka-yoke (mistake-proofing) validation.

## Core Principle

Every subtask must be **atomic**: small enough to complete in one focused session (5-15 minutes), specific enough to verify, and isolated enough to not affect other work.

## The Five Validation Rules

Every subtask MUST pass ALL five rules:

### 1. singleFile
```
MUST modify exactly ONE file
```
- **Pass**: `"file_path": "lib/types.ts"`
- **Fail**: `"file_path": "lib/types.ts, lib/index.ts"`
- **Fail**: Missing file_path

### 2. timeBoxed
```
MUST be 5-15 minutes estimated
```
- **Pass**: `"estimated_minutes": 10`
- **Fail**: `"estimated_minutes": 3` (too small = missing context)
- **Fail**: `"estimated_minutes": 25` (too big = needs splitting)

### 3. verifiable
```
MUST have verification command(s)
```
- **Pass**: `"verification": ["npx tsc --noEmit"]`
- **Pass**: `"verification": ["npm test -- --grep UserType"]`
- **Fail**: `"verification": []`

### 4. hasCodeContext
```
MUST include actual code snippet (>20 characters)
```
- **Pass**: `"existing_code": "export type Role = 'admin' | 'user';"`
- **Fail**: `"existing_code": "line 42"`
- **Fail**: `"existing_code": "see file"`

### 5. hasLocation
```
MUST specify exact insert location
```
Pattern must match: `line \d+|after |before |end of |start of |replace`

- **Pass**: `"after line 44, inside the exports block"`
- **Pass**: `"replace lines 15-20"`
- **Pass**: `"end of file, new export"`
- **Fail**: `"somewhere in the file"`
- **Fail**: `"in the types section"`

## Subtask Schema

```json
{
  "id": "TASK-001-01",
  "parent_task_id": "TASK-001",
  "title": "Add UserType enum",
  "description": "Add enum for user types",
  "file_path": "lib/types.ts",
  "estimated_minutes": 8,
  "dependencies": [],
  "verification": ["npx tsc --noEmit"],
  "status": "pending",
  "attempt_count": 0,
  "blocked_reason": null,
  "code_context": {
    "file_hash": "abc123def456",
    "snapshot_at": "2025-01-19T10:00:00Z",
    "existing_code": "export type Role = 'admin' | 'user';",
    "insert_location": "after line 25, after Role type",
    "pattern_to_follow": "Same union type format"
  }
}
```

## Decomposition Strategies

### By Operation Type
```
"Add user auth" (60 min) →
├── "Add User interface" (10 min) - types.ts
├── "Add auth functions" (12 min) - auth.ts
├── "Add login route" (10 min) - api/login.ts
└── "Add middleware" (10 min) - middleware.ts
```

### By File Section
```
"Update types.ts" (30 min) →
├── "Add enum (lines 1-15)" (8 min)
├── "Add interface (lines 16-30)" (10 min)
└── "Update exports (lines 31-40)" (7 min)
```

### By Dependency Chain
```
Task →
├── [1] "Add type" (no deps)
├── [2] "Add function using type" (deps: 1)
└── [3] "Add API using function" (deps: 2)
```

## Validation Function

```typescript
function validateSubtask(subtask: Subtask): ValidationResult[] {
  const results: ValidationResult[] = [];

  // Rule 1: singleFile
  if (!subtask.file_path) {
    results.push({ valid: false, rule: 'singleFile', reason: 'Missing file_path' });
  } else if (subtask.file_path.includes(',')) {
    results.push({ valid: false, rule: 'singleFile', reason: 'Multiple files' });
  } else {
    results.push({ valid: true, rule: 'singleFile', reason: 'OK' });
  }

  // Rule 2: timeBoxed
  const mins = subtask.estimated_minutes ?? 0;
  if (mins < 5) {
    results.push({ valid: false, rule: 'timeBoxed', reason: `${mins}min < 5min minimum` });
  } else if (mins > 15) {
    results.push({ valid: false, rule: 'timeBoxed', reason: `${mins}min > 15min maximum` });
  } else {
    results.push({ valid: true, rule: 'timeBoxed', reason: `${mins}min OK` });
  }

  // Rule 3: verifiable
  if (!subtask.verification?.length) {
    results.push({ valid: false, rule: 'verifiable', reason: 'No verification commands' });
  } else {
    results.push({ valid: true, rule: 'verifiable', reason: 'Has verification' });
  }

  // Rule 4: hasCodeContext
  const codeLen = subtask.code_context?.existing_code?.length ?? 0;
  if (codeLen < 20) {
    results.push({ valid: false, rule: 'hasCodeContext', reason: `${codeLen} chars < 20 minimum` });
  } else {
    results.push({ valid: true, rule: 'hasCodeContext', reason: `${codeLen} chars OK` });
  }

  // Rule 5: hasLocation
  const loc = subtask.code_context?.insert_location ?? '';
  const pattern = /line \d+|after |before |end of |start of |replace /i;
  if (!pattern.test(loc)) {
    results.push({ valid: false, rule: 'hasLocation', reason: 'Location not specific' });
  } else {
    results.push({ valid: true, rule: 'hasLocation', reason: 'Location specific' });
  }

  return results;
}
```

## Common Mistakes

| Mistake | Why It's Wrong | Fix |
|---------|---------------|-----|
| "Update several files" | Violates singleFile | Split into one subtask per file |
| "Quick 2-min fix" | Too small = missing context | Add more detail, combine with related change |
| "Major refactor" (45 min) | Too large | Split into 3-4 focused changes |
| "Change line 42" | No code context | Include actual code snippet |
| "Somewhere in types" | Vague location | Specify "after line X" or "after Y block" |

## File Hash for Drift Detection

Capture hash when breaking down:
```bash
cat file.ts | sha256sum | cut -c1-12
```

Before executing, verify hash matches. If changed:
1. Log drift detected
2. Re-read file
3. Find new location for existing_code
4. Adapt or re-breakdown

## References

See `references/validation-rules.md` for detailed examples and edge cases.
