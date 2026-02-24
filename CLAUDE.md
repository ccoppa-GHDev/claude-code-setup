# Claude Code System Configuration

This repo manages the global ~/.claude/ configuration that powers /begin project setup.

## What This Repo Contains
- Global CLAUDE.md, /begin command, templates, agents, skills, MCP catalog, hooks
- All files here represent the current production baseline

## How to Work on This Repo
- Read existing files before proposing changes — understand the architecture first
- Changes should be surgical, not rewrites
- Track rationale for every change
- After changes: run install.sh to sync to ~/.claude/

## Architecture Reference
- See SETUP-GUIDE.md for full system documentation
- See SKILLS-INDEX.md for the skills catalog

## About Me
- **Name**: {{YOUR_NAME}}
- **Role**: {{YOUR_ROLE — e.g., Developer, Agency Owner, Tech Lead}}
- **Experience**: {{Beginner / Intermediate / Advanced}} with code
- **Stack**: {{YOUR_PRIMARY_LANGUAGES_AND_FRAMEWORKS — e.g., TypeScript, React, Python, Node.js}}

## Security — Non-Negotiable
- NEVER put API keys, passwords, tokens, or secrets in code files
- ALWAYS use environment variables (`.env`) for sensitive data
- ALWAYS add `.env` to `.gitignore` before any commit
- If you see exposed secrets, STOP and warn me immediately

## Workflow
- IMPORTANT: Plan before coding. Do not jump straight to implementation on non-trivial tasks
- Read existing code before changing anything — understand, then act
- Explain approach in 1-2 sentences before implementing
- Make small, focused changes — not big rewrites
- Run tests/typecheck after changes before saying "done"
- If something seems wrong with my request, ask before proceeding

## Communication
- Be direct and concise — definitive answers over hedging
- Short answers when short works; depth when depth is needed
- Explain the "why" not just the "what"
- If unsure, say so — don't guess

## Don't Do This
- Don't add dependencies without asking
- Don't over-engineer when simple works
- Don't change code style without a reason
- Don't create or overwrite key project files (CLAUDE.md, config files) without asking
- Don't give long explanations when short ones work
- Don't create new scripts/tools when something already exists for that task

## Skills Library
Available skills at `~/.claude/skills-library/`. Read `~/.claude/skills-library/SKILLS-INDEX.md` to find relevant skills for the current task. Only read full SKILL.md files when a skill matches the work being done.
