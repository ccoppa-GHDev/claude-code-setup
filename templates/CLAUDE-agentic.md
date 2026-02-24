# Project: {{SYSTEM_NAME}}

## What This Is
<!-- 1-2 sentences: what the system automates and its core value prop -->

## Architecture
This system separates probabilistic decision-making from deterministic execution.

- **Layer 1 — Instructions**: Markdown SOPs defining goals, inputs, tools, outputs, edge cases. Live in `.claude/skills/`
- **Layer 2 — Orchestration (You)**: Read instructions, call scripts, handle errors, update docs with learnings
- **Layer 3 — Execution**: Deterministic Python/Node scripts for API calls, data processing, file operations. Live in `execution/`

**Why this matters:** 90% accuracy per step = 59% over 5 steps. Push complexity into deterministic code. You focus on decision-making.

## Key Directories
- `.claude/skills/` — SOPs and skill definitions (SKILL.md + scripts/)
- `execution/` — Shared Python/Node execution scripts
- `.tmp/` — Intermediate files (never commit, always regenerable)
- `.env` — API keys and environment variables

## Commands
```bash
python3 execution/{{script_name}}.py    # Run execution scripts
npm run test                             # If tests exist
```

## Operating Principles
1. **Check for existing tools first** — search `execution/` and skill scripts before writing new ones
2. **Self-anneal when things break** — fix → test → update the instruction doc → system is now stronger
3. **Instructions are living documents** — update with API limits, edge cases, better approaches. Don't create or overwrite instructions without asking
4. **Deliverables live in the cloud** — Google Sheets, Slides, etc. Local files in `.tmp/` are only for processing

## Subagents
For available subagent definitions, see `.claude/agents/`. Subagents are read-only reporters — all code changes happen in the parent agent.

## Verification
After modifying any execution script: run it with test inputs to verify before reporting success. For scripts that consume paid API credits, check with me first.

## Error Recovery
Errors are learning opportunities:
1. Read error message and stack trace
2. Fix the script
3. Test with real inputs
4. Update the relevant instruction doc with what you learned
5. System is now stronger
