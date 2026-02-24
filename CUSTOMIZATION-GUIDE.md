# Customization Guide

This package is a ready-to-deploy Claude Code environment. Before installing, customize these files to match your setup.

---

## Required: Personalize Your Identity (2 files)

Claude Code uses the "About Me" section to calibrate responses to your experience level, tailor code examples to your stack, and communicate at the right depth.

### File 1: `deploy/CLAUDE.md`
This is the production global config that gets deployed to `~/.claude/CLAUDE.md`. Replace the placeholders:

```markdown
## About Me
- **Name**: {{YOUR_NAME}}                          ← Your first name
- **Role**: {{YOUR_ROLE}}                           ← e.g., "Senior Developer", "Freelancer", "CTO at Acme"
- **Experience**: {{Beginner / Intermediate / Advanced}} ← How experienced you are with code
- **Stack**: {{YOUR_PRIMARY_LANGUAGES_AND_FRAMEWORKS}}  ← e.g., "Python, Django, PostgreSQL, React"
```

### File 2: `CLAUDE.md` (repo root)
Same "About Me" section — this one is for when you're working on the config repo itself. Match it to what you put in `deploy/CLAUDE.md`.

---

## Optional: Review the Skills Library

The `skills-library/` contains 45+ skills across these categories:

| Category | Examples | Remove if you don't use |
|----------|----------|------------------------|
| Document Generation | docx, pdf, pptx, xlsx | Rarely — these are broadly useful |
| Web Development | frontend-design, seo-audit, React/Next.js patterns | If you don't build web apps |
| Data Architecture | supabase-postgres, firestore-schemas | If you don't use these databases |
| Infrastructure | n8n, mcp-builder, trigger-dev | If you don't use these platforms |
| Consulting | salesforce-enterprise-consultant | If you don't do Salesforce work |
| Agentic Workflows | scrape-leads, gmail-label, youtube-outliers, etc. | If you don't build automations |

**To remove a skill:** Delete its folder from `skills-library/` and remove its row from `skills-library/SKILLS-INDEX.md`.

**To add a skill:** Create a folder with a `SKILL.md` file and add a row to `SKILLS-INDEX.md`.

---

## Optional: Review MCP Servers

Edit `mcp-catalog/MCP-Servers.md` to match servers you actually use or have API keys for. The file is organized into three tiers:

- **Tier 1 (Essential):** GitHub, Sequential Thinking, Context7 — recommended for all projects
- **Tier 2 (Recommended):** Brave Search, Memory Server, PostgreSQL — matched by keyword
- **Tier 3 (Specialized):** Playwright, Supabase, n8n, Trigger.dev, etc. — only when needed

Remove servers you'll never use. Add any MCP servers you rely on that aren't listed.

---

## Optional: Platform-Specific Hooks

The notification hook in `begin-config.json` uses `osascript` which is **macOS only**.

**For Linux**, replace the notification command with:
```json
"command": "notify-send 'Claude Code' 'Claude needs attention' 2>/dev/null || true"
```

**For Windows (WSL)**, replace with:
```json
"command": "powershell.exe -Command \"[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('Claude needs attention','Claude Code')\" 2>/dev/null || true"
```

**To disable notifications entirely**, remove the `notifications` block from `begin-config.json`.

---

## Optional: Review Agent Library

The agents in `agents-library/` are general-purpose and don't need customization. However, you can:

- **Remove agents you won't use** — e.g., `email-classifier.md` if you don't automate Gmail
- **Add your own** — follow the frontmatter standard (`model: inherit`, `allowed-tools: [list]`)
- **Adjust review depth** — edit reviewer prompts to focus on what matters most to your codebase

---

## Optional: Customize Commands

The `commands/` directory contains slash commands available in every project:

| Command | Purpose | Customize? |
|---------|---------|-----------|
| `/begin` | Project initialization | Usually no — it's designed to be generic |
| `/plan` | Implementation planning | Optional — adjust planning prompts to your style |
| `/review` | Code review | Optional — tune review criteria |
| `/status` | Project status check | Optional — adjust what "status" means for your projects |
| `/summary` | Session summary | Optional — change where summaries are saved |
| `/history` | Conversation history | Usually no |
| `/security-check` | Security scanning | Usually no |
| `/new-workflow` | Scaffold agentic workflow | Only if you build agentic workflows |

---

## Installation

After customizing:

```bash
# 1. Make install script executable
chmod +x install.sh

# 2. Run the installer
./install.sh

# 3. Verify
claude    # Open Claude Code anywhere
/         # Should show begin, plan, review, etc.
/begin    # Initialize your first project
```

---

## After Installation

- **Add skills later:** Drop a folder into `~/.claude/skills-library/`, update SKILLS-INDEX.md, re-run `install.sh`
- **Modify config:** Edit files in this repo, then re-run `install.sh` to sync
- **Version control:** `git init` this directory to track your configuration changes over time
