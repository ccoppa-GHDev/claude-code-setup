---
name: gmail-inbox
description: Manage emails across multiple Gmail accounts with unified tooling. Use when user asks to check email, read inbox, label emails, archive messages, or manage Gmail across accounts.
category: email-campaigns
path: agentic
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
env_vars: []
triggers: manual
---

# Gmail Inbox Management

## Goal
Check and manage emails across multiple Gmail accounts using unified tooling.

## Scripts
- `./scripts/gmail_unified.py` - Check and manage inboxes
- `./scripts/gmail_multi_auth.py` - Authenticate accounts
- `./scripts/gmail_bulk_label.py` - Bulk labeling
- `./scripts/gmail_create_filters.py` - Create filters
- `./scripts/gmail_auth.py` - Auth helper

## Quick Reference

```bash
# Check unread across all accounts
python3 ./scripts/gmail_unified.py --query "is:unread" --limit 50

# Check specific account only
python3 ./scripts/gmail_unified.py --query "is:unread" --account [ACCOUNT_ALIAS]

# List registered accounts
python3 ./scripts/gmail_unified.py --accounts

# Label and archive emails
python3 ./scripts/gmail_unified.py --query "from:notifications@" --label "Notifications" --archive

# Mark as read
python3 ./scripts/gmail_unified.py --query "from:noreply@" --mark-read

# Dry run (preview)
python3 ./scripts/gmail_unified.py --query "subject:invoice" --label "Invoices" --dry-run
```

## Account Registry

Configure accounts in `gmail_accounts.json`:

| Account | Email | Credentials | Token |
|---------|-------|-------------|-------|
| [ACCOUNT_1_ALIAS] | [ACCOUNT_1_EMAIL] | credentials.json | token_[ACCOUNT_1_ALIAS].json |
| [ACCOUNT_2_ALIAS] | [ACCOUNT_2_EMAIL] | credentials_[ACCOUNT_2_ALIAS].json | token_[ACCOUNT_2_ALIAS].json |

## Troubleshooting Auth Errors

**"Token file not found"**
```bash
python3 ./scripts/gmail_multi_auth.py --account [ACCOUNT_ALIAS] --email [EMAIL]
```

**"invalid_scope: Bad Request"**
```bash
rm token_[ACCOUNT_ALIAS].json
python3 ./scripts/gmail_multi_auth.py --account [ACCOUNT_ALIAS] --email [EMAIL]
```

**"Failed to authenticate"**
Check that credentials.json exists in root directory.

## Required Scopes
- `gmail.modify` - Read/write emails
- `gmail.labels` - Create/manage labels
- `gmail.settings.basic` - Manage settings
- `spreadsheets` - Google Sheets access
- `drive` - Google Drive access

## Credentials Location
All credential files should be in the workspace root:
- `credentials.json` / `credentials_[ACCOUNT_ALIAS].json` - OAuth client configs
- `token_*.json` - Auth tokens (auto-generated)
- `gmail_accounts.json` - Account registry
