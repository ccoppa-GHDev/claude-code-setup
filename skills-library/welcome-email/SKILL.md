---
name: welcome-email
description: Send welcome email sequence to new clients. Use when user asks to send welcome emails, onboard new client with emails, or trigger welcome sequence.
category: email-campaigns
path: agentic
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
env_vars:
  - ANTHROPIC_API_KEY
triggers: webhook
---

# Welcome Client Emails

## Goal
Send a 3-email welcome sequence from different team members when a new client signs. Establishes relationships across the team.

## Scripts
- `./scripts/welcome_client_emails.py` - Send welcome sequence

## Configuration
Set team member details in `.env` or script config:
```
SENDER_EMAIL=[YOUR_EMAIL]
COMPANY_NAME=[YOUR_COMPANY]
BOOKING_URL=[YOUR_BOOKING_URL]
TEAM_MEMBERS=[TEAM_MEMBER_1],[TEAM_MEMBER_2],[TEAM_MEMBER_3]
```

## Process
1. Receive client info (name, email, company)
2. Send email from [TEAM_MEMBER_1] (welcome, expectations)
3. Send email from [TEAM_MEMBER_2] (technical setup)
4. Send email from [TEAM_MEMBER_3] (support intro)

## Usage

```bash
python3 ./scripts/welcome_client_emails.py \
  --client_name "John Doe" \
  --client_email "john@company.com" \
  --company "Acme Corp"
```

## Email Structure
Each email is personalized with client details and sent from different team members to establish relationships. Emails are sent with a 15-second delay between each to avoid spam filters.
