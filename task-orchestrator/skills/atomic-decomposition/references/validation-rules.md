# Validation Rules Reference

Detailed examples and edge cases for poka-yoke validation.

## Rule 1: singleFile

### Valid Examples
```json
{ "file_path": "lib/types.ts" }
{ "file_path": "src/components/Button.tsx" }
{ "file_path": "api/routes/users.ts" }
```

### Invalid Examples
```json
{ "file_path": "lib/types.ts, lib/index.ts" }  // Multiple files
{ "file_path": "" }                             // Empty
{ }                                             // Missing
```

### Edge Cases
- **New file creation**: Valid if single file: `"file_path": "lib/newfile.ts"`
- **File deletion**: Valid if single file, but use `"action": "delete"` field
- **Rename**: Split into delete old + create new

---

## Rule 2: timeBoxed (5-15 minutes)

### Time Estimation Guide

| Task Type | Typical Time |
|-----------|--------------|
| Add single enum/type | 5-7 min |
| Add interface (3-5 fields) | 7-10 min |
| Add simple function | 8-12 min |
| Modify existing function | 8-12 min |
| Add API route | 10-15 min |
| Wire up integration | 10-15 min |

### Too Small (<5 min)
Usually means missing context:
- "Add one line" → What line? Where? What does it do?
- "Fix typo" → What's the context around it?

**Fix**: Add more detail to make it 5+ minutes with proper context.

### Too Large (>15 min)
Needs splitting:
- "Implement auth system" → Split by file/function
- "Add CRUD operations" → Split by operation
- "Refactor module" → Split by transformation step

**Fix**: Identify natural break points (different files, different functions, dependencies).

---

## Rule 3: verifiable

### Good Verification Commands

```json
// Type checking
{ "verification": ["npx tsc --noEmit"] }

// Specific test
{ "verification": ["npm test -- --grep 'UserType'"] }

// Multiple checks
{ "verification": ["npx tsc --noEmit", "npm run lint"] }

// Build check
{ "verification": ["npm run build"] }
```

### Bad Verification
```json
{ "verification": [] }           // Empty
{ "verification": ["check it"] } // Not executable
{ }                              // Missing
```

### Choosing Verification
1. **Type changes**: `npx tsc --noEmit`
2. **Logic changes**: Relevant unit test
3. **API changes**: `curl` or integration test
4. **UI changes**: Browser test or screenshot comparison
5. **Build changes**: `npm run build`

---

## Rule 4: hasCodeContext (>20 chars)

### Good Code Context
```json
{
  "existing_code": "export type Role = 'admin' | 'user' | 'guest';",
  "insert_location": "after line 25"
}
```

```json
{
  "existing_code": "export async function getUser(id: string): Promise<User> {\n  return db.users.findOne({ id });\n}",
  "insert_location": "after getUser function"
}
```

### Bad Code Context
```json
{ "existing_code": "line 42" }        // Just a reference
{ "existing_code": "see the file" }   // Not actual code
{ "existing_code": "export type" }    // Too short (12 chars)
```

### Why 20+ Characters?
- Short snippets are ambiguous
- Need enough context to find exact location
- Need enough to understand what's there
- Prevents "line 42" type references

---

## Rule 5: hasLocation

### Valid Location Patterns

```
line \d+        → "line 42", "after line 100"
after           → "after the Role type", "after line 25"
before          → "before the export block"
end of          → "end of file", "end of function"
start of        → "start of file", "start of class"
replace         → "replace lines 15-20", "replace the TODO"
```

### Examples
```json
{ "insert_location": "after line 44, inside PassType union" }
{ "insert_location": "end of file, add new export" }
{ "insert_location": "replace lines 15-20 with implementation" }
{ "insert_location": "before the closing brace of UserService class" }
{ "insert_location": "start of file, add import statement" }
```

### Invalid
```json
{ "insert_location": "somewhere in the file" }
{ "insert_location": "in the types" }
{ "insert_location": "where appropriate" }
{ "insert_location": "" }
```

---

## Combined Validation Example

### Fully Valid Subtask
```json
{
  "id": "TASK-001-03",
  "title": "Add UserStatus enum",
  "file_path": "lib/types.ts",
  "estimated_minutes": 8,
  "verification": ["npx tsc --noEmit"],
  "code_context": {
    "existing_code": "export type Role = 'admin' | 'user' | 'guest';",
    "insert_location": "after line 25, after Role type definition"
  }
}
```

Validation:
```
[PASS] singleFile: lib/types.ts
[PASS] timeBoxed: 8 minutes
[PASS] verifiable: npx tsc --noEmit
[PASS] hasCodeContext: 47 chars
[PASS] hasLocation: "after line 25..."
Result: VALID
```

### Invalid Subtask
```json
{
  "id": "TASK-001-03",
  "title": "Update types and index",
  "file_path": "lib/types.ts, lib/index.ts",
  "estimated_minutes": 25,
  "verification": [],
  "code_context": {
    "existing_code": "line 25",
    "insert_location": "in the types"
  }
}
```

Validation:
```
[FAIL] singleFile: Multiple files specified
[FAIL] timeBoxed: 25 minutes > 15 max
[FAIL] verifiable: No verification commands
[FAIL] hasCodeContext: 7 chars < 20 minimum
[FAIL] hasLocation: Pattern not matched
Result: INVALID - 5 rules failed
```
