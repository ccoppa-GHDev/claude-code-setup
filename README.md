# Claude Code Starter Kit

A complete, pre-configured environment for Claude Code that gives you intelligent project initialization, a curated skills library, automated agents, MCP server recommendations, and formatting hooks — all from a single `/begin` command.

## What You Get

- **`/begin` command** — Detects your project type (Web/SaaS or Agentic Workflow), recommends skills, agents, and MCP servers, generates a tailored project config, and scaffolds everything
- **45+ skills** — Document generation, web development, data architecture, infrastructure, consulting, and automation workflows. Loaded on-demand, never all at once
- **8 agents** — 4 deep reviewers (code quality, security, performance, documentation) + 4 fast subagents (code review, QA, research, email classification)
- **MCP server catalog** — Tiered recommendations with install commands and env var docs
- **Formatting hooks** — Prettier, ESLint, Ruff auto-run on file changes
- **7 additional slash commands** — `/plan`, `/review`, `/status`, `/summary`, `/security-check`, `/history`, `/new-workflow`

## Quick Start

```bash
# 1. Read the customization guide and personalize your config
#    (at minimum: your name, role, experience, and tech stack)
open CUSTOMIZATION-GUIDE.md

# 2. Install
chmod +x install.sh
./install.sh

# 3. Use it
cd ~/projects/my-project
claude
# Type: /begin
```

## Documentation

| File | What it covers |
|------|---------------|
| **CUSTOMIZATION-GUIDE.md** | What to personalize before installing |
| **SETUP-GUIDE.md** | Full architecture documentation and design decisions |

## Prerequisites

- **Claude Code** installed (`npm install -g @anthropic-ai/claude-code`)
- **Node.js 18+**
- **Python 3.10+** (for agentic workflow hooks)
- **Git** (recommended for version-controlling your config)

## How It Works

```
You type /begin
  → Claude detects project type (Web/SaaS or Agentic)
  → Scans skills index, agents, MCP catalog
  → Asks about your project
  → Recommends matching resources
  → Generates project CLAUDE.md from template
  → Copies selected skills + agents into project
  → Installs MCP servers
  → Configures hooks
  → Done. Start building.
```

Skills are never all loaded at once. Claude reads a lightweight index (~72 lines), then only reads individual skill files when they match the current task. This keeps the context window lean.

## License

This is a personal configuration kit. Use it however you want. No warranty.
