---
name: begin
description: Initialize or update a Claude Code project. Detects project type, discovers available skills/agents/MCP servers, and scaffolds the optimal environment.
allowed-tools: Read, Write, Bash, Grep, Glob, Task, WebSearch, WebFetch
---

# /begin — Project Setup Command

You are a Claude Code configuration assistant. Set up or enhance this project by discovering available resources and matching them to what the user is building.

**Critical Rule:** Keep under 10 MCP servers enabled per project. Context window (200k) can shrink to 70k with too many tools.

---

## PHASE 1: Mode Selection

Ask the user:

> **What would you like to do?**
> 1. **New Setup** — Initialize a new project from scratch
> 2. **Update** — Add to existing setup without overwriting
> 3. **Reset** — Clear existing config and start fresh

If **Update**, skip to Phase 4 (show current config, ask what to add/change).
If **Reset**, delete `.claude/` and `CLAUDE.md`, then proceed as New Setup.

---

## PHASE 2: Detect Project Path

### 2.1 Auto-detect from filesystem

```bash
# Check for Web/SaaS indicators
ls package.json next.config.* vite.config.* tsconfig.json src/ app/ components/ 2>/dev/null
# Check for Agentic indicators
ls execution/ directives/ .claude/skills/ workflows/ *.py modal.toml 2>/dev/null
# Check existing setup
ls CLAUDE.md .claude/ .mcp.json 2>/dev/null
```

### 2.2 Determine path

**If Web/SaaS signals dominate** (package.json, tsconfig, src/, components/):
> I detected a **Web/SaaS application** project. Confirm? Or is this an **Agentic Workflow** system?

**If Agentic signals dominate** (execution/, directives/, modal.toml, Python scripts):
> I detected an **Agentic Workflow** project. Confirm? Or is this a **Web/SaaS application**?

**If ambiguous or empty directory:**
> **What are you building?**
> 1. **Web / SaaS** — Next.js, React, API, web application
> 2. **Agentic Workflow** — Automation, skills, scripts, n8n workflows

Store the selected path as `PROJECT_PATH` (either `web` or `agentic`) for all subsequent phases.

---

## PHASE 3: Discover Available Resources

### 3.1 Scan Skills Library

```bash
cat ~/.claude/skills-library/SKILLS-INDEX.md 2>/dev/null
```

Read the index and match skills to the project. DO NOT scan individual SKILL.md files — the index has everything needed for recommendations.

### 3.2 Scan Agents Library

```bash
cat ~/.claude/agents-library/README.md 2>/dev/null
for f in ~/.claude/agents-library/reviewers/*.md ~/.claude/agents-library/subagents/*.md; do
  [ -f "$f" ] && head -6 "$f"
done
```

### 3.3 Read MCP Server Catalog

```bash
cat ~/.claude/mcp-catalog/MCP-Servers.md 2>/dev/null
```

Parse tiers, context costs, "Recommend when" keywords, env vars, and install commands.

### 3.4 Check Already Configured MCP

```bash
claude mcp list 2>/dev/null
```

### 3.5 Load Hooks Config

```bash
cat ~/.claude/begin-config.json 2>/dev/null
```

---

## PHASE 4: Understand the Project

> **Tell me about this project:**
> - What are you building? (e.g., SaaS app, client website, Salesforce integration, automation workflow)
> - What's the main tech stack?
> - Any specific capabilities you'll need? (e.g., database access, browser testing, API integrations)

---

## PHASE 5: Match Resources to Project

### 5.1 Skills Matching
Compare the user's project against the skills index. Recommend skills where there's clear alignment. Group by relevance.

### 5.2 Agent Matching

**Web/SaaS path defaults:** code-quality, security, performance, documentation (reviewers) + qa (subagent)
**Agentic path defaults:** code-review, research, qa (subagents)

Adjust based on project specifics.

### 5.3 MCP Server Matching (Tier Logic)

**Tier 1 (Essential):** Auto-select all (GitHub, Sequential Thinking, Context7).
**Tier 2 (Recommended):** Match "Recommend when" keywords against project description.
**Tier 3 (Specialized):** Only recommend on strong keyword match.

**Path-specific bias:**
- Web/SaaS: favor Next.js DevTools, Supabase, Playwright, PostgreSQL
- Agentic: favor n8n, FireCrawl, Memory Server

Count total servers. Warn at 8, block at 10+.

### 5.4 Hook Matching

**Web/SaaS:** Prettier, ESLint, block-dangerous, notifications
**Agentic:** block-dangerous, notifications (add Python hooks if Python-heavy)

### 5.5 Present Recommendations

```markdown
## 📚 Skills — Recommended: [N]
| Skill | Why |
|-------|-----|

## 🤖 Agents — Recommended: [N]
| Agent | Type | Why |
|-------|------|-----|

## 🔌 MCP Servers — Selected: [N] / 10 max
| Server | Tier | Context Cost | Requires |
|--------|------|--------------|----------|

## 🪝 Hooks — Recommended: [N]
| Hook | What it does |
|------|-------------|

⚠️ Server Count: [N] [warning if >= 8]
```

> **Confirm your selections.** Anything to add or remove?

---

## PHASE 6: Create Project CLAUDE.md

Read the appropriate template:

```bash
# Web/SaaS path
cat ~/.claude/templates/CLAUDE-app-dev.md

# Agentic path
cat ~/.claude/templates/CLAUDE-agentic.md
```

Fill in the template placeholders using the project info gathered in Phase 4. Ask the user to confirm:

> Here's your project CLAUDE.md based on the **[Web/SaaS | Agentic]** template. Review and let me know any changes.

---

## PHASE 7: Present Final Plan

```markdown
# /begin Setup Plan

**Project:** [NAME]
**Path:** [Web/SaaS | Agentic Workflow]
**Mode:** [New | Update | Reset]

### CLAUDE.md → [Create | Update | Skip]
### Skills: [N] to activate
### Agents: [N] to activate
### MCP Servers: [N] to configure [⚠️ if >= 8]
### Hooks: [N] to configure

**Proceed?** Yes / Modify / Cancel
```

---

## PHASE 8: Execute

### 8.1 Directory Structure
```bash
mkdir -p .claude/skills .claude/agents .claude/commands
```

### 8.2 Write CLAUDE.md
Write approved CLAUDE.md to project root.

### 8.3 Activate Skills
Copy only the selected skills from the global library:
```bash
cp -r ~/.claude/skills-library/[skill-name] .claude/skills/
```

### 8.4 Activate Agents
```bash
cp ~/.claude/agents-library/reviewers/[agent].md .claude/agents/ 2>/dev/null
cp ~/.claude/agents-library/subagents/[agent].md .claude/agents/ 2>/dev/null
```

### 8.5 Configure MCP Servers
Use exact commands from MCP-Servers.md. Always use `--scope project`. Show required env vars with instructions.

### 8.6 Configure Hooks
Write selected hooks to `.claude/settings.json`.

---

## PHASE 9: Summary

```
## ✅ /begin Complete!

**Path**: [Web/SaaS | Agentic Workflow]
**CLAUDE.md**: [Created | Updated]
**Skills**: [N] activated
**Agents**: [N] activated
**MCP Servers**: [N] configured
**Hooks**: [N] configured

📄 Report: BEGIN-SETUP-REPORT.md

**Next steps:**
1. Run `/mcp` to verify server connections
2. Set required environment variables: [list]
3. Review CLAUDE.md and adjust if needed
```

Save detailed report to `BEGIN-SETUP-REPORT.md`.
