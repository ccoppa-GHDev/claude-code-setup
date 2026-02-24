---
name: n8n-workflow-automation
description: Master skill for n8n workflow automation covering 525+ nodes, AI agents, and the n8n-mcp server. Use when building, configuring, validating, or debugging n8n workflows. Covers code nodes (JavaScript/Python), expression syntax, MCP tool usage, node configuration, validation errors, and architectural workflow patterns (webhook, HTTP API, database, AI agent, scheduled tasks). Also use when asking about n8n expressions, webhook data access, node configuration, validation loops, or workflow architecture.
category: infrastructure
path: reference
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
env_vars: []
triggers: manual
---

# n8n Workflow Automation — Master Skill

Complete guide for building n8n workflows with the n8n-mcp server. Consolidates 7 specialized skill domains into a unified reference.

---

## MCP Server Configuration

**n8n-mcp** provides conversational access to 525+ n8n nodes including AI-capable nodes and triggers.

**GitHub**: https://github.com/czlonkowski/n8n-mcp

```bash
claude mcp add n8n-mcp --scope project \
  -e MCP_MODE=stdio \
  -e LOG_LEVEL=error \
  -e DISABLE_CONSOLE_OUTPUT=true \
  -- npx n8n-mcp
```

| Variable | Required | Description |
|----------|----------|-------------|
| `MCP_MODE` | Yes | Set to `stdio` |
| `LOG_LEVEL` | No | Set to `error` to reduce noise |
| `DISABLE_CONSOLE_OUTPUT` | No | Set to `true` for cleaner output |

---

## Critical Rules (Read First!)

These gotchas appear across ALL n8n work. Internalize them before anything else.

### 1. Webhook Data Lives Under `.body`
The #1 mistake across all skill domains. Webhook payload data is nested:

```javascript
// ❌ WRONG — empty or undefined
{{ $json.email }}

// ✅ CORRECT — data is under .body
{{ $json.body.email }}
```

This applies in expressions, Code nodes, and anywhere you access webhook data.

### 2. Expressions Use `{{ }}` — Code Nodes Do NOT
```javascript
// In expressions (Set node, field values):
{{ $json.body.name }}

// In Code nodes (direct JavaScript/Python):
$input.first().json.body.name    // JS
_input.first().json["body"]["name"]  // Python
```

**Never use `{{ }}` inside Code nodes. Never use bare `$json.field` in expression fields.**

### 3. nodeType Format Differs by Context
```
Search/validation tools:  nodes-base.slack
Workflow node definitions: n8n-nodes-base.slack
```

Use `nodes-base.*` with `search_nodes`, `get_node`, `validate_node`.
Use `n8n-nodes-base.*` in workflow `nodes[].type` fields.

### 4. POST Requests Need `sendBody: true`
```javascript
{
  method: "POST",
  url: "https://api.example.com/data",
  sendBody: true,           // ← Required!
  bodyParametersJson: "{...}"
}
```

### 5. Always Use Parameterized SQL Queries
```javascript
// ❌ SQL injection risk
query: `SELECT * FROM users WHERE id = '${$json.id}'`

// ✅ Parameterized
query: "SELECT * FROM users WHERE id = $1"
parameters: ["={{ $json.id }}"]
```

### 6. Python Code Nodes: NO External Libraries
Python mode has **no** `requests`, `pandas`, `numpy`, `bs4`, or any pip packages. Standard library only (`json`, `datetime`, `re`, `base64`, `hashlib`, `urllib`, `math`, `collections`). Use JavaScript for 95% of Code node tasks.

### 7. Validation is Iterative
Expect 2-3 validate → fix cycles. Average: 23s thinking + 58s fixing per cycle. This is normal — don't try to get it perfect on the first pass.

### 8. Set Timezone Explicitly for Schedules
```javascript
{
  rule: { interval: [{ field: "hours", betweenStart: 9, betweenEnd: 17 }] },
  timezone: "America/Los_Angeles"  // ← Always specify!
}
```

---

## Skill Domain Quick Router

Use this to find the right reference for your task:

| Task | Primary Reference | Key Tool |
|------|------------------|----------|
| Write JavaScript in Code node | [code-nodes-javascript.md](reference/code-nodes-javascript.md) | — |
| Write Python in Code node | [code-nodes-python.md](reference/code-nodes-python.md) | — |
| Write `{{ }}` expressions | [expression-syntax.md](reference/expression-syntax.md) | — |
| Find/search n8n nodes | [mcp-tools-guide.md](reference/mcp-tools-guide.md) | `search_nodes` |
| Get node details/docs | [mcp-tools-guide.md](reference/mcp-tools-guide.md) | `get_node` |
| Configure a specific node | [node-configuration.md](reference/node-configuration.md) | `get_node` |
| Validate node/workflow | [validation-errors.md](reference/validation-errors.md) | `validate_node` |
| Create/update workflow | [mcp-tools-guide.md](reference/mcp-tools-guide.md) | `n8n_create_workflow` |
| Fix validation errors | [validation-errors.md](reference/validation-errors.md) | `validate_node` |
| Build webhook workflow | [webhook-http-patterns.md](reference/webhook-http-patterns.md) | — |
| Build API integration | [webhook-http-patterns.md](reference/webhook-http-patterns.md) | — |
| Build database workflow | [database-scheduled.md](reference/database-scheduled.md) | — |
| Build AI agent workflow | [ai-agent-patterns.md](reference/ai-agent-patterns.md) | `ai_agents_guide` |
| Build scheduled automation | [database-scheduled.md](reference/database-scheduled.md) | — |
| Design workflow architecture | [workflow-patterns.md](reference/workflow-patterns.md) | `search_templates` |

---

## MCP Tool Quick Reference

### Discovery Tools

**`search_nodes`** — START HERE for finding nodes
```
search_nodes({ query: "slack message" })
→ Returns matching nodes with nodeType for further queries
```

**`get_node`** — Primary node reference (95% success rate)
```
get_node({ nodeType: "nodes-base.slack", detail: "standard" })

Detail levels:
  minimal  → Name, description, version (quick check)
  standard → + all properties, operations (DEFAULT — use this)
  full     → + examples, all metadata (when standard isn't enough)
```

**`search_templates`** — Find example workflows
```
search_templates({ query: "webhook slack notification" })
```

**`ai_agents_guide`** — AI workflow guidance
```
ai_agents_guide()
→ Returns AI connection types, tool patterns, memory options
```

### Workflow Tools

**`n8n_create_workflow`** — Create new workflow
**`n8n_update_partial_workflow`** — Most used tool (38,287 uses, 56s avg between edits)
  - 17 operations: addNodes, updateNode, addConnections, cleanStaleConnections, activateWorkflow, etc.
  - Smart parameters: `branch` for IF, `case` for Switch
**`n8n_deploy_template`** — Deploy from template library
**`n8n_test_workflow`** — Test execution
**`n8n_executions`** — View execution history

### Validation Tools

**`validate_node`** — Validate single node config
```
validate_node({
  nodeType: "nodes-base.slack",
  config: { resource: "message", operation: "post", channel: "#general" },
  profile: "runtime"    // minimal | runtime (recommended) | ai-friendly | strict
})
```

**`validate_workflow`** — Validate entire workflow structure
**`n8n_autofix_workflow`** — Auto-fix operator structure issues (IF/Switch metadata)

---

## Code Node Essentials

### JavaScript (Recommended for 95% of tasks)

**Mode Selection**:
- **Run Once for All Items** (95% of use cases): Process entire dataset, return array
- **Run Once for Each Item** (5%): Process one item, return single object

**Data Access Patterns**:
```javascript
// All items from previous node
const items = $input.all();

// First item only
const first = $input.first();

// Current item (Each Item mode only)
const current = $input.item;

// Specific node's output
const data = $node["Node Name"].json;

// Webhook data (REMEMBER: under .body!)
const email = $input.first().json.body.email;
```

**Return Format** (MUST be array of `{json: {...}}` objects):
```javascript
return items.map(item => ({
  json: {
    id: item.json.id,
    name: item.json.name,
    processed: true
  }
}));
```

**Built-in Helpers** (no imports needed):
```javascript
// HTTP requests
const response = await $helpers.httpRequest({ method: 'GET', url: '...' });

// Date/time (Luxon)
const now = DateTime.now();
const formatted = DateTime.fromISO(date).toFormat('yyyy-MM-dd');

// JSON querying
const result = $jmespath(data, 'people[?age > `30`].name');

// Persistent storage (survives executions)
const store = $getWorkflowStaticData('global');
store.lastRun = new Date().toISOString();
```

**NOT Available**: axios, lodash, moment, fetch, require(), npm packages.

### Python (Use only when Python-specific logic needed)

```python
# Data access (note: underscore prefix, not dollar sign)
items = _input.all()
first = _input.first()
current = _input.item  # Each Item mode

# Return format
return [{"json": {"id": item.json["id"], "processed": True}} for item in items]
```

**Available**: json, datetime, re, base64, hashlib, urllib, math, random, statistics, collections, itertools, functools, string, textwrap, uuid, csv, io, os.path, copy, decimal, fractions, operator, enum, dataclasses, typing, abc.

**NOT Available**: requests, pandas, numpy, bs4, scipy, sklearn, psycopg2, or ANY pip package.

→ **Full reference**: [code-nodes-javascript.md](reference/code-nodes-javascript.md) | [code-nodes-python.md](reference/code-nodes-python.md)

---

## Expression Syntax Essentials

**Format**: `={{ expression }}` (always prefixed with `=`)

**Core Variables**:
```javascript
$json           // Current item's data
$json.body      // Webhook payload (CRITICAL!)
$node["Name"]   // Another node's output (needs .json)
$now            // Current timestamp (Luxon DateTime)
$env.VAR_NAME   // Environment variable
$input.item     // Current input item
$input.all()    // All input items (in expressions: $input.all()[0].json.field)
$execution.id   // Current execution ID
```

**Fields with spaces**: `$json["Field Name"]` (bracket notation required)

**Safe navigation**: `$json.data?.user?.name || 'Unknown'`

**Where NOT to use `{{ }}`**:
- Inside Code nodes (use direct variable access)
- Webhook URL paths
- Credential fields

→ **Full reference**: [expression-syntax.md](reference/expression-syntax.md)

---

## Node Configuration Essentials

### 8-Step Configuration Workflow
1. `search_nodes` → Find the right node
2. `get_node` (standard detail) → See operations and properties
3. Select resource + operation
4. Identify required fields for chosen operation
5. Configure required fields
6. Add optional fields as needed
7. `validate_node` → Check configuration
8. Fix errors → Validate again (iterate!)

### displayOptions: Why Fields Appear/Disappear
Fields are conditionally shown based on other field values:
```json
{
  "displayOptions": {
    "show": {
      "operation": ["post"],
      "resource": ["message"]
    }
  }
}
```
The `text` field for Slack only appears when `resource=message` AND `operation=post`. Use `get_node` with `search_properties` mode to discover these dependencies.

### Top Node Configuration Patterns

**HTTP Request (GET)**:
```javascript
{ method: "GET", url: "https://api.example.com/data", sendQuery: true,
  queryParameters: { page: "1", limit: "100" } }
```

**HTTP Request (POST)**:
```javascript
{ method: "POST", url: "https://api.example.com/data",
  sendBody: true, bodyParametersJson: '{"name": "={{$json.name}}"}' }
```

**Slack (post message)**:
```javascript
{ resource: "message", operation: "post",
  channel: "#general", text: "Hello from n8n!" }
```

**Postgres (parameterized query)**:
```javascript
{ operation: "executeQuery",
  query: "SELECT * FROM users WHERE status = $1 LIMIT $2",
  parameters: ["active", "100"] }
```

**IF Node (string comparison)**:
```javascript
{ conditions: { boolean: [{
  value1: "={{ $json.status }}", operation: "equals", value2: "active"
}]}}
```

**Schedule Trigger (daily)**:
```javascript
{ rule: { interval: [{ field: "cronExpression", expression: "0 9 * * *" }] },
  timezone: "America/Los_Angeles" }
```

→ **Full reference**: [node-configuration.md](reference/node-configuration.md)

---

## Validation Quick Reference

### Error Types by Frequency
| Type | Frequency | Auto-Fix | Action |
|------|-----------|----------|--------|
| `missing_required` | 45% | ❌ | Use `get_node` to find required fields |
| `invalid_value` | 28% | ❌ | Check allowed values in error message |
| `type_mismatch` | 12% | ❌ | Convert to correct type (number vs string) |
| `invalid_expression` | 8% | ❌ | Check `{{ }}` syntax, node references |
| `invalid_reference` | 5% | ❌ | Fix node name spelling, clean stale connections |
| `operator_structure` | 2% | ✅ | Trust auto-sanitization, don't manually fix |

### Validation Profiles
- **`minimal`** — Quick checks during editing
- **`runtime`** — **RECOMMENDED** for pre-deployment (balanced)
- **`ai-friendly`** — Reduces false positives by 60% for AI-generated configs
- **`strict`** — Maximum safety, many warnings (use pre-production)

### The Validation Loop
```
Configure → validate_node (23s thinking) → Read errors → Fix → validate_node again (58s fixing) → Repeat (2-3 iterations typical)
```

### Auto-Sanitization (runs on every workflow save)
- Binary operators (equals, contains, etc.): Removes incorrect `singleValue`
- Unary operators (isEmpty, isNotEmpty, true, false): Adds `singleValue: true`
- IF/Switch metadata: Adds `conditions.options` automatically
- **Don't manually fix these** — they're handled on save

### Recovery Strategies
- **Start Fresh**: Note required fields → minimal config → add features one by one
- **Clean Stale Connections**: `n8n_update_partial_workflow({ operations: [{ type: "cleanStaleConnections" }] })`
- **Auto-fix**: `n8n_autofix_workflow({ id: "...", applyFixes: false })` to preview, then `applyFixes: true`

→ **Full reference**: [validation-errors.md](reference/validation-errors.md)

---

## Workflow Pattern Selection

### The 5 Core Patterns

**1. Webhook Processing** (35% of workflows, 813 searches — most common)
```
Webhook → Validate → Transform → Action → Response
```
- Data under `$json.body` (not `$json`)
- Response modes: `onReceived` (instant 200) vs `lastNode` (custom response)
- Always validate incoming data, add authentication

**2. HTTP API Integration** (892 templates)
```
Trigger → HTTP Request → Transform → Action → Error Handler
```
- Auth via credentials system (never hardcode!)
- Handle pagination (offset, cursor, link header)
- Rate limiting: Wait between batches, respect headers, exponential backoff
- `continueOnFail: true` for error handling paths

**3. Database Operations** (456 templates)
```
Schedule → Query → Transform → Write → Verify
```
- Parameterized queries always (SQL injection prevention)
- Batch processing for large datasets
- Incremental sync with timestamps
- Read-only access for AI agent tools

**4. AI Agent Workflow** (234 templates, 270 AI nodes)
```
Trigger → AI Agent (Model + Tools + Memory) → Output
```
- 8 AI connection types: `ai_languageModel`, `ai_tool`, `ai_memory`, `ai_outputParser`, `ai_embedding`, `ai_vectorStore`, `ai_document`, `ai_textSplitter`
- **ANY n8n node can be a tool** — connect via `ai_tool` port (NOT main port)
- Memory essential for conversations (Window Buffer Memory recommended)
- Tool descriptions are critical — AI uses them to decide when to call
- Read-only DB access for safety

**5. Scheduled Tasks** (28% of workflows)
```
Schedule → Fetch → Process → Deliver → Log
```
- Set timezone explicitly (DST handling)
- Prevent overlapping executions
- Error Trigger workflow for failure alerts
- Batch processing for large data

### Workflow Creation Checklist
1. **Plan**: Identify pattern → List nodes (`search_nodes`) → Design data flow → Plan error handling
2. **Build**: Create trigger → Add data sources → Configure auth → Add transforms → Add outputs → Add error handling
3. **Validate**: `validate_node` each node → `validate_workflow` → Test with sample data → Handle edge cases
4. **Deploy**: Review settings → `activateWorkflow` → Monitor first runs → Document

→ **Full reference**: [workflow-patterns.md](reference/workflow-patterns.md) | [webhook-http-patterns.md](reference/webhook-http-patterns.md) | [database-scheduled.md](reference/database-scheduled.md) | [ai-agent-patterns.md](reference/ai-agent-patterns.md)

---

## Common Workflow Examples

### Webhook → Slack Notification
```
1. Webhook (path: "form-submit", POST, responseMode: "lastNode")
2. IF ({{ $json.body.email }} is not empty)
3. Set (map: user_email={{ $json.body.email }}, user_name={{ $json.body.name }})
4. Slack (resource: message, operation: post, channel: #notifications, text: "New form: ={{ $json.user_name }}")
5. Webhook Response (200, { status: "success" })
```

### Scheduled Report → Email
```
1. Schedule Trigger (daily 9 AM, timezone: America/Los_Angeles)
2. HTTP Request (GET analytics API)
3. Code (aggregate data, compute totals)
4. Email (send formatted report)
5. Error Trigger → Slack (#ops-alerts)
```

### AI Chat Assistant
```
1. Webhook (path: "chat", POST)
2. AI Agent
   ├─ OpenAI Chat Model (ai_languageModel)
   ├─ HTTP Request Tool (ai_tool) — search knowledge base
   ├─ Postgres Tool (ai_tool) — query customer data (READ-ONLY user!)
   └─ Window Buffer Memory (ai_memory, contextWindowLength: 10)
3. Webhook Response (send AI reply)
```

### Database Sync
```
1. Schedule (every 15 min)
2. Postgres (SELECT * FROM users WHERE updated_at > $1, params: [last_sync])
3. IF (records exist)
4. Set (map schema)
5. MySQL (UPSERT users)
6. Postgres (UPDATE sync_log SET last_sync = NOW())
```

---

## Reference Files

| File | Domain | Lines | Covers |
|------|--------|-------|--------|
| [code-nodes-javascript.md](reference/code-nodes-javascript.md) | Code (JS) | ~650 | Modes, data access, return format, `$helpers`, Luxon, JMESPath, static data, top errors |
| [code-nodes-python.md](reference/code-nodes-python.md) | Code (Python) | ~550 | Python modes, `_input` access, standard library, limitations, common errors |
| [expression-syntax.md](reference/expression-syntax.md) | Expressions | ~450 | `{{ }}` format, core variables, 15 common mistakes with fixes, real examples |
| [mcp-tools-guide.md](reference/mcp-tools-guide.md) | MCP Tools | ~500 | Tool selection, search/get_node/validate/workflow tools, smart parameters |
| [node-configuration.md](reference/node-configuration.md) | Node Config | ~600 | Operation-aware config, displayOptions, dependencies, top 20 node patterns |
| [validation-errors.md](reference/validation-errors.md) | Validation | ~600 | 9 error types, false positives, profiles, auto-sanitization, recovery |
| [workflow-patterns.md](reference/workflow-patterns.md) | Architecture | ~400 | 5 core patterns, selection guide, data flow patterns, creation checklist |
| [webhook-http-patterns.md](reference/webhook-http-patterns.md) | Webhook/API | ~650 | Webhook processing, HTTP API integration, auth, pagination, rate limiting |
| [database-scheduled.md](reference/database-scheduled.md) | DB/Schedule | ~550 | Database ops, sync, batch processing, scheduled tasks, cron, timezone |
| [ai-agent-patterns.md](reference/ai-agent-patterns.md) | AI Agents | ~500 | 8 connection types, tool config, memory, prompts, security |

---

## Integration Flow Between Domains

```
[1. PATTERN SELECTION]     → workflow-patterns.md
        ↓                    "What kind of workflow am I building?"
[2. NODE DISCOVERY]        → mcp-tools-guide.md (search_nodes, get_node)
        ↓                    "What nodes do I need?"
[3. CONFIGURATION]         → node-configuration.md + expression-syntax.md
        ↓                    "How do I configure each node?"
[4. CODE LOGIC]            → code-nodes-javascript.md / code-nodes-python.md
        ↓                    "Need custom logic in Code nodes?"
[5. VALIDATION]            → validation-errors.md (validate_node, validate_workflow)
        ↓                    "Is my config correct?"
[6. DEPLOYMENT]            → mcp-tools-guide.md (n8n_create_workflow, activateWorkflow)
                             "Create, test, activate"
```

---

## Summary

**This skill covers**:
- 525+ n8n nodes via n8n-mcp server
- JavaScript and Python Code node development
- Expression syntax with 15 common mistake fixes
- 40+ MCP tools for node discovery, configuration, validation, and workflow management
- Operation-aware node configuration with dependency handling
- 9 validation error types with recovery strategies
- 5 proven architectural patterns covering 90%+ of workflow use cases
- AI agent workflows with 8 connection types

**Always remember**:
1. Webhook data → `$json.body.field`
2. Expressions use `{{ }}`, Code nodes don't
3. `nodes-base.*` for tools, `n8n-nodes-base.*` for workflows
4. Validate iteratively (2-3 cycles is normal)
5. JavaScript for 95% of Code nodes, Python only when needed
6. Parameterized SQL queries always
7. Read-only DB access for AI agent tools
8. Set timezone explicitly for schedules
