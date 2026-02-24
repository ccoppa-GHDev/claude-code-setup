# n8n Workflow Patterns Reference

5 core architectural patterns covering 90%+ of n8n workflow use cases.

---

## Pattern Selection Guide

| Use Case | Pattern | Trigger | Complexity |
|----------|---------|---------|------------|
| Receive data from external systems | **Webhook** | Webhook | Simple-Medium |
| Fetch data from APIs | **HTTP API** | Schedule/Webhook | Medium |
| Sync/query databases | **Database** | Schedule | Medium |
| AI with tools and memory | **AI Agent** | Webhook | Medium-Complex |
| Recurring automation | **Scheduled** | Schedule | Simple-Medium |

### Decision Tree
```
Receiving external events?     → Webhook Processing
Calling external APIs?         → HTTP API Integration
Reading/writing databases?     → Database Operations
Need AI reasoning/tools?       → AI Agent Workflow
Running on a timer?            → Scheduled Tasks
Multiple of the above?         → Combine patterns!
```

---

## The 5 Core Patterns

### 1. Webhook Processing (35% of workflows)
```
Webhook → Validate → Transform → Action → Response
```

Key decisions:
- **Response mode**: `onReceived` (instant 200, async processing) vs `lastNode` (custom response, sync)
- **Authentication**: Token, header, signature verification, IP whitelist
- **Data access**: Always `$json.body.field` (not `$json.field`)

→ **Full reference**: [webhook-http-patterns.md](webhook-http-patterns.md)

### 2. HTTP API Integration (892 templates)
```
Trigger → HTTP Request → Transform → Action → Error Handler
```

Key decisions:
- **Auth method**: Bearer token, API key, Basic Auth, OAuth2
- **Pagination**: Offset, cursor, or Link header
- **Error handling**: `continueOnFail: true` + IF check + retry/fallback
- **Rate limiting**: Wait between batches, respect headers

→ **Full reference**: [webhook-http-patterns.md](webhook-http-patterns.md)

### 3. Database Operations (456 templates)
```
Schedule → Query → Transform → Write → Verify
```

Key decisions:
- **Query style**: Always parameterized (SQL injection prevention)
- **Sync strategy**: Full vs incremental (timestamp-based)
- **Batch processing**: Split In Batches for large datasets
- **Transactions**: Multi-step operations need atomicity

→ **Full reference**: [database-scheduled.md](database-scheduled.md)

### 4. AI Agent Workflow (234 templates)
```
Trigger → AI Agent (Model + Tools + Memory) → Output
```

Key decisions:
- **Model**: GPT-4/Claude for complex, GPT-3.5/Haiku for simple
- **Tools**: Any n8n node via `ai_tool` port
- **Memory**: Window Buffer Memory recommended (last N messages)
- **Security**: Read-only DB access, input sanitization, rate limiting

→ **Full reference**: [ai-agent-patterns.md](ai-agent-patterns.md)

### 5. Scheduled Tasks (28% of workflows)
```
Schedule → Fetch → Process → Deliver → Log
```

Key decisions:
- **Frequency**: Interval (minutes/hours) vs Cron (specific times)
- **Timezone**: Always set explicitly
- **Overlap prevention**: Use locks or execution queuing
- **Error notification**: Error Trigger workflow → Slack/Email

→ **Full reference**: [database-scheduled.md](database-scheduled.md)

---

## Data Flow Patterns

### Linear Flow
```
Trigger → Transform → Action → End
```
Use for: Simple workflows with single path. 42% of workflows are 3-5 nodes.

### Branching Flow
```
Trigger → IF → [True Path] → ...
           └→ [False Path] → ...
```
Use for: Different actions based on conditions.

### Parallel Processing
```
Trigger → [Branch 1] → Merge
       └→ [Branch 2] ↗
```
Use for: Independent operations that run simultaneously.

### Loop Pattern
```
Trigger → Split In Batches → Process → Loop (until done)
```
Use for: Large datasets in chunks. Essential for rate-limited APIs.

### Error Handler Pattern
```
Main Flow → [Success Path]
         └→ [Error Trigger → Alert → Log]
```
Use for: Separate error handling workflow. **Recommended for all production workflows.**

---

## Workflow Creation Checklist

### 1. Planning
- [ ] Identify the pattern (webhook, API, database, AI, scheduled)
- [ ] List required nodes (`search_nodes`)
- [ ] Design data flow (input → transform → output)
- [ ] Plan error handling strategy

### 2. Implementation
- [ ] Create workflow with appropriate trigger
- [ ] Add data source nodes
- [ ] Configure authentication/credentials (never hardcode!)
- [ ] Add transformation nodes (Set, Code, IF)
- [ ] Add output/action nodes
- [ ] Configure error handling (Error Trigger + notifications)

### 3. Validation
- [ ] `validate_node` each node (runtime profile)
- [ ] `validate_workflow` entire workflow
- [ ] Test with sample data
- [ ] Handle edge cases (empty data, errors, timeouts)

### 4. Deployment
- [ ] Review workflow settings (execution order, timeout)
- [ ] `activateWorkflow` operation
- [ ] Monitor first executions
- [ ] Document workflow purpose and data flow

---

## Pattern Statistics

**Trigger Distribution**: Webhook 35%, Schedule 28%, Manual 22%, Service triggers 15%

**Transformation Nodes**: Set 68%, Code 42%, IF 38%, Switch 18%

**Output Channels**: HTTP Request 45%, Slack 32%, Database 28%, Email 24%

**Complexity**: Simple (3-5 nodes) 42%, Medium (6-10) 38%, Complex (11+) 20%

---

## Common Cross-Pattern Gotchas

1. **Webhook data under .body** — Every single time
2. **Expressions in Code nodes** — Don't use `{{ }}` in Code
3. **Hardcoded credentials** — Always use credential system
4. **Missing error handling** — Add Error Trigger to all production workflows
5. **No validation before activation** — Always validate first
6. **Ignoring empty data** — Handle cases where no records/items exist
7. **SQL injection** — Always parameterize queries
8. **Missing timezone** — Schedule triggers default to server timezone
