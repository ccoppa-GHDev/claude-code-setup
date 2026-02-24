---
name: instantly-autoreply
description: Auto-generate intelligent replies to incoming Instantly email threads using knowledge bases. Use when user asks about email auto-replies, Instantly responses, or automated email handling.
category: email-campaigns
path: agentic
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
env_vars:
  - INSTANTLY_API_KEY
  - ANTHROPIC_API_KEY
triggers: webhook
---

# Instantly Auto-Reply

## Goal
Auto-generate intelligent replies to incoming emails from Instantly campaigns using campaign-specific knowledge bases.

## Scripts
- `./scripts/instantly_autoreply.py` - Main auto-reply script

## How It Works
1. Receives incoming email thread from Instantly webhook
2. Looks up campaign ID in knowledge base sheet
3. Retrieves campaign context (offers, credentials, tone)
4. Generates contextual reply using Claude
5. Sends reply through Instantly API

## Knowledge Base
Spreadsheet: `[KB_SPREADSHEET_ID]` — Configure in `.env` or script

Each row contains:
- Campaign ID
- Campaign Name
- Knowledge Base (service details, offers, credentials)
- Reply Examples (tone/style guidance)

## Usage

```bash
# Process incoming thread
python3 ./scripts/instantly_autoreply.py --thread_id <id>
```

## Environment
```
INSTANTLY_API_KEY=your_key
ANTHROPIC_API_KEY=your_key
KB_SPREADSHEET_ID=your_spreadsheet_id
```
