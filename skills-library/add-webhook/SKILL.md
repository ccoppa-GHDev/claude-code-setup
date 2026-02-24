---
name: add-webhook
description: Add new Modal webhooks for event-driven execution. Use when user asks to create a webhook, add an endpoint, or set up event triggers.
category: infrastructure
path: agentic
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
env_vars:
  - MODAL_TOKEN_ID
  - MODAL_TOKEN_SECRET
triggers: manual
---

# Add Webhook

## Goal
Create new Modal webhooks for event-driven Claude orchestration.

## Process

1. **Create Directive File**
   Create `directives/your_directive.md` with:
   - Goal
   - Inputs
   - Process steps
   - Outputs
   - Edge cases

2. **Add to webhooks.json**
   Add entry to `execution/webhooks.json`:
   ```json
   {
     "your-webhook-slug": {
       "directive": "your_directive",
       "description": "What this webhook does",
       "tools": ["send_email", "read_sheet", "update_sheet"]
     }
   }
   ```

3. **Deploy**
   ```bash
   modal deploy execution/modal_webhook.py
   ```

4. **Test**
   ```bash
   curl "https://[MODAL_USERNAME]--claude-orchestrator-directive.modal.run?slug=your-webhook-slug"
   ```

## Available Tools for Webhooks
- `send_email`
- `read_sheet`
- `update_sheet`

## Endpoints
- List: `https://[MODAL_USERNAME]--claude-orchestrator-list-webhooks.modal.run`
- Execute: `https://[MODAL_USERNAME]--claude-orchestrator-directive.modal.run?slug={slug}`
