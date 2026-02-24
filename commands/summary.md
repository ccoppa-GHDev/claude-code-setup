---
description: Create a session summary of work completed, decisions made, and next steps
allowed-tools: Read, Grep, Glob, Bash
---

# Session Summary

Generate a concise summary of the current working session.

## Instructions

1. **Review recent git activity** — `git log --oneline -20` and `git diff --stat HEAD~5..HEAD` (adjust range as needed)
2. **Identify files changed** — what was added, modified, deleted
3. **Read commit messages** for context on what was done and why
4. **Check current state** — any uncommitted work, open branches

## Output Format

```markdown
# Session Summary — [date]

## Objectives
- [What was the user trying to accomplish]

## Completed Work
- [Bullet list of what was done, with file references]

## Files Modified
| File | Change Type |
|------|-------------|
| path/to/file | Added / Modified / Deleted |

## Key Decisions
- [Any architectural or design decisions made during the session]

## Issues Resolved
- [Bugs fixed, errors resolved]

## Next Steps
- [What remains to be done]
```

Present the summary to the user. If they want it saved to a file, ask where.
