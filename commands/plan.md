---
description: Create a detailed implementation plan before coding. Use for complex features or refactoring.
argument-hint: [feature or task description]
allowed-tools: Read, Grep, Glob
---

# Planning Mode

Create a detailed implementation plan for the following request:

**Request:** $ARGUMENTS

## Instructions

### Phase 1: Understanding
1. **Clarify the Goal**
   - What is the user trying to achieve?
   - What are the success criteria?
   - What are the constraints?

2. **Gather Context**
   - Read relevant existing code
   - Identify dependencies
   - Check for related implementations

### Phase 2: Analysis
3. **Assess Impact**
   - Which files need changes?
   - Are there breaking changes?
   - What tests need updating?

4. **Identify Risks**
   - Technical challenges
   - Edge cases to handle
   - Performance considerations

### Phase 3: Planning
5. **Create Step-by-Step Plan**
   
   For each step, specify:
   - [ ] **Step N**: Brief description
     - Files to modify: `path/to/file.ts`
     - Changes: What specifically changes
     - Tests: Which tests to add/update
     - Verification: How to confirm it works

6. **Estimate Complexity**
   - Simple (1-2 files, < 1 hour)
   - Medium (3-5 files, 1-3 hours)
   - Complex (5+ files, > 3 hours)

## Output Format

```markdown
# Implementation Plan: [Feature Name]

## Summary
[1-2 sentence overview]

## Steps

### Step 1: [Title]
- **Files:** `file1.ts`, `file2.ts`
- **Changes:** [Description]
- **Tests:** [Test requirements]
- **Verification:** [How to verify]

### Step 2: [Title]
...

## Risks & Mitigations
- Risk 1: [Description] → Mitigation: [Approach]

## Questions for User
- [Any clarifications needed?]
```

---

**⚠️ DO NOT IMPLEMENT YET**

Present the plan and wait for user approval before proceeding with implementation.
