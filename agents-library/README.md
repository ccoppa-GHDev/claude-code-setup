# Agents Library

## Two Types of Agents

### Reviewers (`reviewers/`)
Deep, specialized review agents with extensive checklists. Use for thorough analysis of completed work.

| Agent | Purpose |
|-------|---------|
| code-quality.md | Clean code, SOLID, readability, maintainability |
| security.md | OWASP, auth, injection, crypto, access control |
| performance.md | Complexity, queries, memory, async patterns |
| documentation.md | Docs accuracy, API docs, README verification |

**When to use:** After implementing a feature, before committing, before PR review.

### Subagents (`subagents/`)
Lightweight, fast agents that return structured output. Use for quick tasks that benefit from isolated context.

| Agent | Purpose |
|-------|---------|
| code-review.md | Quick pass/fail code review with zero prior context |
| qa.md | Generate tests, run them, report pass/fail |
| test-specialist.md | Comprehensive test generation and coverage analysis |
| research.md | Deep web/file research without polluting parent context |
| email-classifier.md | Gmail classification into Action/Waiting/Reference |

**When to use:** Mid-task validation, parallel investigation, batch processing.

## Frontmatter Standard
All agents use:
- `model: inherit` — inherits the parent model (most flexible)
- `allowed-tools:` — Claude Code standard tool key
