# Claude Code Setup Guide

## Repo Structure

```
Claude-Code-System/
├── deploy/
│   └── CLAUDE.md                     ← Production global config (deployed to ~/.claude/)
├── CLAUDE.md                         ← Repo-specific config (stays in this project)
├── begin-config.json                 ← Hook definitions (formatting, safety, notifications)
├── install.sh                        ← Deployment script: syncs this repo → ~/.claude/
│
├── commands/
│   ├── begin.md                      ← /begin slash command (project initialization)
│   ├── plan.md                       ← /plan (implementation planning)
│   ├── review.md                     ← /review (code review)
│   ├── security-check.md             ← /security-check (secret/vuln scanning)
│   ├── status.md                     ← /status (project status)
│   ├── summary.md                    ← /summary (session summary)
│   ├── history.md                    ← /history (conversation history)
│   └── new-workflow.md               ← /new-workflow (scaffold agentic workflow)
│
├── templates/
│   ├── CLAUDE-app-dev.md             ← Project template for Web/SaaS applications
│   └── CLAUDE-agentic.md             ← Project template for agentic workflow systems
│
├── agents-library/
│   ├── README.md                     ← Agent usage guide
│   ├── reviewers/                    ← Deep review agents (4)
│   │   ├── code-quality.md
│   │   ├── security.md
│   │   ├── performance.md
│   │   └── documentation.md
│   └── subagents/                    ← Lightweight task agents (5)
│       ├── code-review.md
│       ├── qa.md
│       ├── test-specialist.md
│       ├── research.md
│       └── email-classifier.md
│
├── skills-library/
│   ├── SKILLS-INDEX.md               ← Lightweight catalog (45 skills)
│   └── [45 skill folders]/           ← Each contains SKILL.md + optional reference/ and scripts/
│
├── mcp-catalog/
│   └── MCP-Servers.md                ← Tiered MCP server catalog
│
└── SETUP-GUIDE.md                    ← This file
```

---

## Prerequisites

1. **Claude Code installed**: `npm install -g @anthropic-ai/claude-code`
2. **Node.js 18+**: Required for Claude Code and MCP servers
3. **GitHub CLI**: `brew install gh` (macOS) — Claude uses this for git operations
4. **Python 3.10+**: Required for agentic workflow projects
5. **Ruff** (optional): `pip install ruff` — Python formatting hook

---

## Installation

### Quick Install

```bash
cd /path/to/Claude-Code-System
./install.sh
```

The install script:
1. Creates the `~/.claude/` directory structure
2. Copies `deploy/CLAUDE.md` → `~/.claude/CLAUDE.md`
3. Copies all commands → `~/.claude/commands/`
4. Copies templates → `~/.claude/templates/`
5. Copies agents (reviewers + subagents) → `~/.claude/agents-library/`
6. Copies skills library (SKILLS-INDEX.md + 45 skill folders) → `~/.claude/skills-library/`
7. Copies MCP catalog → `~/.claude/mcp-catalog/`
8. Copies hooks config → `~/.claude/begin-config.json`

### Verification

After running `install.sh`, verify:

```bash
echo "=== Global CLAUDE.md ===" && wc -l ~/.claude/CLAUDE.md
echo "=== Commands ===" && ls ~/.claude/commands/
echo "=== Templates ===" && ls ~/.claude/templates/
echo "=== Agents ===" && ls ~/.claude/agents-library/reviewers/ ~/.claude/agents-library/subagents/
echo "=== Skills Index ===" && wc -l ~/.claude/skills-library/SKILLS-INDEX.md
echo "=== Skills Count ===" && ls -d ~/.claude/skills-library/*/ | wc -l
echo "=== MCP Catalog ===" && ls ~/.claude/mcp-catalog/MCP-Servers.md
echo "=== Hooks Config ===" && ls ~/.claude/begin-config.json
```

Expected output:
- CLAUDE.md: 39 lines
- Commands: 8 files (begin, history, new-workflow, plan, review, security-check, status, summary)
- Templates: CLAUDE-app-dev.md, CLAUDE-agentic.md
- Reviewers: 4 files (code-quality, security, performance, documentation)
- Subagents: 5 files (code-review, qa, test-specialist, research, email-classifier)
- Skills Index: 72 lines
- Skills: 45 folders
- MCP Catalog: present
- Hooks Config: present

---

## How It Works

### Starting a New Project

```bash
cd ~/projects/my-new-app
git init
claude
```

Then type: `/begin`

The command will:
1. Ask: New Setup, Update, or Reset?
2. Auto-detect project type (Web/SaaS or Agentic) from filesystem signals
3. Scan the skills index, agents library, and MCP catalog
4. Ask about your project
5. Match and recommend skills, agents, MCP servers, and hooks
6. Present recommendations for your approval
7. Generate a project CLAUDE.md from the appropriate template
8. Execute: copy selected skills/agents, install MCP servers, configure hooks
9. Save a setup report

### Progressive Disclosure in Action

The system is designed so Claude only loads what it needs:

```
Session starts
  └── ~/.claude/CLAUDE.md loads (39 lines — always)
  └── {project}/CLAUDE.md loads (60-80 lines — always)
       └── SKILLS-INDEX.md read when task might need a skill (72 lines)
            └── Individual SKILL.md read only if skill matches task
                 └── reference/ docs read only if SKILL.md says to
```

This keeps context lean. Claude never has all 45 skills in context — just the 1-2 it needs right now.

### Context Window Budget

| Component | Lines | Load Timing |
|-----------|-------|-------------|
| Claude Code system prompt | ~50 instructions | Always |
| Global CLAUDE.md | 39 lines (~24 instructions) | Always |
| Project CLAUDE.md | ~60-80 lines (~40 instructions) | Always |
| **Total baseline** | **~115 instructions** | **Well under 200 limit** |
| Skills Index | 72 lines | On demand |
| Individual SKILL.md | 50-200 lines | On demand |
| Agent definition | 30-60 lines | On demand |

---

## Customization

### Adding a New Skill
1. Create `skills-library/my-skill/SKILL.md` in this repo
2. Add a row to `skills-library/SKILLS-INDEX.md`
3. Run `./install.sh` to deploy

### Adding a New Agent
1. Create the .md file in `agents-library/reviewers/` or `agents-library/subagents/`
2. Follow the frontmatter standard: `model: inherit`, `allowed-tools: [list]`
3. Update `agents-library/README.md`
4. Run `./install.sh` to deploy

### Adding a New Command
1. Create the .md file in `commands/` with proper frontmatter
2. Run `./install.sh` to deploy

### Adding a New MCP Server
1. Append to `mcp-catalog/MCP-Servers.md` under the appropriate tier using the format documented at the bottom of that file
2. Run `./install.sh` to deploy

### Modifying Hooks
Edit `begin-config.json`. The `path` field (`web`, `agentic`, or `both`) controls which hooks are offered for each project type. Run `./install.sh` to deploy.

---

## Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| Global skills, project activation | Skills available everywhere, only loaded when needed. No wasted context. |
| Two CLAUDE.md templates | Web/SaaS and Agentic have fundamentally different architectures, commands, and patterns. |
| 39-line global CLAUDE.md | HumanLayer research: frontier models follow ~150-200 instructions. System prompt uses ~50. This leaves headroom. |
| Skills index over full scanning | Reading 45 SKILL.md files would consume ~5,000 tokens. The index is 72 lines. |
| Hooks for formatting | HumanLayer + Anthropic: never send an LLM to do a linter's job. Deterministic tools are faster and cheaper. |
| Agents: reviewers vs subagents | Different tools, different purposes. Reviewers go deep; subagents go fast. |
| model: inherit for all agents | Most flexible — inherits whatever model the parent is using. No hardcoded model strings to update. |
| deploy/ for production CLAUDE.md | Repo root CLAUDE.md has repo-management context; deploy/ version is the clean global config. |
