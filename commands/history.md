---
description: View recent Claude Code conversation history in a scannable format
allowed-tools: Read, Bash
---

Please read my global conversation history from ~/.claude/history.jsonl and present it in an easy-to-scan format.

For each conversation, show:
- Entry number
- Date/time (human readable format: "Nov 20, 2025 15:48")
- Project name (just the folder name, not full path)
- First 60-80 characters of the conversation topic
- Session ID

Present this as a clean table, showing the most recent 10-20 conversations by default.

If the user wants to see more, ask them how many they'd like to see.

Make it easy to identify which conversation is which so I can resume it later.
