---
description: Scaffold a new workflow subdirectory with CLAUDE.md, instructions, and scripts
argument-hint: [workflow name]
allowed-tools: Read, Write, Bash, Grep, Glob
---

# New Workflow: $ARGUMENTS

Scaffold a new workflow under `workflows/` with the standard agentic structure.

## Phase 1: Gather Info

If `$ARGUMENTS` is empty, ask:

> **What should this workflow be called?** (e.g., lead-enrichment, invoice-processing, onboarding-flow)

Then ask:

> **What does this workflow do?** (1-2 sentences — what it automates and what the output is)

Store the name as `WORKFLOW_NAME` (kebab-case) and the purpose as `WORKFLOW_PURPOSE`.

## Phase 2: Check for Conflicts

```bash
ls workflows/$WORKFLOW_NAME 2>/dev/null
```

If the directory already exists, warn and ask to proceed or pick a different name.

## Phase 3: Scan Shared Execution Scripts

```bash
ls execution/*.py execution/*.js execution/*.ts 2>/dev/null
```

List any scripts found and note which might be relevant based on the workflow purpose. Present them:

> **These shared scripts exist in `execution/`. Any of these relevant to your workflow?**
> - `execution/script_name.py` — [brief description from reading first few lines]

If no `execution/` directory exists, skip this step.

## Phase 4: Create Directory Structure

```bash
mkdir -p workflows/$WORKFLOW_NAME/scripts
```

## Phase 5: Generate CLAUDE.md

Write `workflows/$WORKFLOW_NAME/CLAUDE.md`:

```markdown
# Workflow: [WORKFLOW_NAME as Title Case]

## Purpose
[WORKFLOW_PURPOSE from Phase 1]

## How to Run
1. Read `instructions.md` for the full SOP
2. Execute scripts in `scripts/` as directed by instructions
3. Use shared scripts from `execution/` where applicable

## Key Scripts
| Script | Purpose |
|--------|---------|
| scripts/ | [Workflow-specific scripts go here] |

## Shared Dependencies
[List any relevant execution/ scripts identified in Phase 3, or "None yet"]

## Notes
- Update this file as the workflow evolves
- Add edge cases and API limits to instructions.md as you discover them
```

## Phase 6: Generate instructions.md

Write `workflows/$WORKFLOW_NAME/instructions.md`:

```markdown
# [WORKFLOW_NAME as Title Case] — Instructions

## Goal
[WORKFLOW_PURPOSE]

## Inputs
- [ ] [What this workflow needs to start — files, API credentials, data sources]

## Steps

### Step 1: [First action]
**Script:** `scripts/[name].py` or `execution/[shared].py`
**Input:** [What it takes]
**Output:** [What it produces]

### Step 2: [Next action]
...

## Edge Cases
- [Document API limits, rate limits, error conditions as you discover them]

## Output
- **Deliverable:** [What the workflow produces — file, API call, report, etc.]
- **Location:** [Where the output goes — cloud service, .tmp/, etc.]
```

## Phase 7: Confirm

Show the user what was created:

```
✓ Created workflows/$WORKFLOW_NAME/
  ├── CLAUDE.md          — Workflow overview and script registry
  ├── instructions.md    — SOP template (fill in as you build)
  └── scripts/           — Workflow-specific scripts

Next steps:
1. Fill in the Steps section of instructions.md
2. Create scripts in scripts/ for each step
3. Test with real inputs before running at scale
```
