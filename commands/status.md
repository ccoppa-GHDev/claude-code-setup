---
description: Check current project status — git state, recent work, and next steps
allowed-tools: Read, Grep, Glob, Bash
---

# Project Status

Analyze the current state of this project and provide a concise status report.

## Instructions

1. **Read project CLAUDE.md** to understand what this project is
2. **Check git status** — staged, unstaged, untracked files
3. **Review recent commits** — `git log --oneline -10`
4. **Identify current branch** and whether it's ahead/behind remote
5. **Check for open TODOs** — search for TODO/FIXME/HACK in the codebase
6. **Check build/test health** — if commands are defined in CLAUDE.md, note them (don't run unless asked)

## Output Format

```
## Project Status: [project name from CLAUDE.md]

**Branch:** [current branch] [ahead/behind info]
**Last commit:** [hash] [message] [time ago]

### Working Tree
- Staged: [N files]
- Modified: [N files]
- Untracked: [N files]

### Recent Activity (last 5 commits)
- [hash] [message] [date]

### Open TODOs
- [file:line] [TODO text] (or "None found")

### Suggested Next Steps
- [Based on current state, what seems like the logical next action]
```
