# n8n MCP Tools Guide

Reference for using n8n-mcp server tools to discover, configure, validate, and manage n8n workflows.

---

## Tool Selection Quick Guide

| Goal | Tool | Key Parameters |
|------|------|---------------|
| Find nodes | `search_nodes` | `query` |
| Get node details | `get_node` | `nodeType`, `detail` level |
| Search properties | `get_node` | mode: `search_properties` |
| Compare versions | `get_node` | mode: `compare` |
| Validate node config | `validate_node` | `nodeType`, `config`, `profile` |
| Validate workflow | `validate_workflow` | `workflow`, `options` |
| Auto-fix issues | `n8n_autofix_workflow` | `id`, `applyFixes` |
| Create workflow | `n8n_create_workflow` | workflow definition |
| Update workflow | `n8n_update_partial_workflow` | `id`, `operations` |
| Deploy template | `n8n_deploy_template` | template ID |
| Test workflow | `n8n_test_workflow` | `id` |
| View executions | `n8n_executions` | `id`, filters |
| Find examples | `search_templates` | `query` |
| AI guidance | `ai_agents_guide` | — |

---

## Discovery: search_nodes

**Always start here** when looking for nodes.

```
search_nodes({ query: "slack message" })
search_nodes({ query: "send email" })
search_nodes({ query: "postgres database" })
search_nodes({ query: "ai agent" })
```

**Returns**: Node names, types, descriptions. Use the `nodeType` from results in subsequent `get_node` calls.

**CRITICAL**: Use `nodes-base.*` format (without `n8n-` prefix) for search and get_node tools.

---

## Discovery: get_node

**The primary node reference tool** — 95% success rate with `standard` detail.

### 6 Modes

**1. info (default)** — Node details at chosen detail level
```
get_node({ nodeType: "nodes-base.slack", detail: "standard" })
```

Detail levels:
- `minimal` — Name, description, version (quick check)
- `standard` — All properties, operations, options (DEFAULT — use 95% of the time)
- `full` — Everything including examples, all metadata

**2. docs** — Node documentation
```
get_node({ nodeType: "nodes-base.slack", mode: "docs" })
```

**3. search_properties** — Find specific properties
```
get_node({
  nodeType: "nodes-base.slack",
  mode: "search_properties",
  query: "channel"
})
```

**4. versions** — Available type versions
```
get_node({ nodeType: "nodes-base.slack", mode: "versions" })
```

**5. compare** — Compare two versions
```
get_node({
  nodeType: "nodes-base.slack",
  mode: "compare",
  version1: 1,
  version2: 2
})
```

**6. breaking / migrations** — Breaking changes and migration paths

### When to Use Each Detail Level

```
Quick check of node existence → minimal
Configure node operations     → standard (DEFAULT)
Standard isn't enough         → full
Find specific property        → search_properties mode
```

Average time: 18 seconds from search → having essentials.

---

## nodeType Format: The Critical Distinction

```
For MCP tools (search/validate):    nodes-base.slack
For workflow node definitions:       n8n-nodes-base.slack
```

**Why this matters**: Using the wrong format silently fails or returns errors.

**AI/Langchain nodes**: `@n8n/n8n-nodes-langchain.*`

Examples:
```
search_nodes:  nodes-base.httpRequest
get_node:      nodes-base.httpRequest
validate_node: nodes-base.httpRequest

Workflow JSON:
  "type": "n8n-nodes-base.httpRequest"

AI nodes in workflow:
  "type": "@n8n/n8n-nodes-langchain.agent"
  "type": "@n8n/n8n-nodes-langchain.lmChatOpenAi"
```

---

## Validation: validate_node

**Validates individual node configuration.**

```
validate_node({
  nodeType: "nodes-base.slack",
  config: {
    resource: "message",
    operation: "post",
    channel: "#general",
    text: "Hello!"
  },
  profile: "runtime"
})
```

### Profiles
| Profile | Use When | False Positive Rate |
|---------|----------|-------------------|
| `minimal` | Quick checks during editing | Lowest (misses real issues) |
| `runtime` | **Pre-deployment (RECOMMENDED)** | Balanced |
| `ai-friendly` | AI-generated configs | Reduced by 60% |
| `strict` | Production/critical workflows | Highest (many warnings) |

### Reading Results
```javascript
{
  valid: false,
  errors: [     // MUST fix — blocks execution
    { type: "missing_required", property: "channel", message: "...", fix: "..." }
  ],
  warnings: [   // SHOULD fix — doesn't block
    { type: "best_practice", message: "...", suggestion: "..." }
  ],
  suggestions: [ // OPTIONAL — nice to have
    { type: "optimization", message: "..." }
  ]
}
```

1. Check `valid` field first
2. Fix all `errors` (must fix)
3. Review `warnings` (context-dependent)
4. Consider `suggestions` (optional)

---

## Validation: validate_workflow

**Validates entire workflow structure.**

```
validate_workflow({
  workflow: { nodes: [...], connections: {...} },
  options: {
    validateNodes: true,
    validateConnections: true,
    validateExpressions: true,
    profile: "runtime"
  }
})
```

**Catches**: Broken connections, circular dependencies, multiple triggers, disconnected nodes, invalid references.

---

## Auto-Fix: n8n_autofix_workflow

**Automatically fixes operator structure issues.**

```
// Preview first
n8n_autofix_workflow({ id: "workflow-id", applyFixes: false })

// Then apply
n8n_autofix_workflow({ id: "workflow-id", applyFixes: true })
```

**Fixes**: Binary operator singleValue issues, unary operator metadata, IF/Switch conditions.options.

**Does NOT fix**: Broken connections, branch count mismatches, missing required fields.

---

## Workflow Management: n8n_update_partial_workflow

**Most used tool** (38,287 uses, 56s average between edits). Supports 17 operations.

### Key Operations

**Add nodes**:
```
n8n_update_partial_workflow({
  id: "workflow-id",
  operations: [{
    type: "addNodes",
    nodes: [{
      type: "n8n-nodes-base.slack",
      name: "Notify Team",
      typeVersion: 2,
      position: [600, 300],
      parameters: { resource: "message", operation: "post", channel: "#general" }
    }]
  }]
})
```

**Update node**:
```
operations: [{ type: "updateNode", name: "Notify Team", parameters: { channel: "#alerts" } }]
```

**Add connections**:
```
operations: [{
  type: "addConnections",
  connections: [{
    source: "Webhook", sourceOutput: 0,
    target: "Notify Team", targetInput: 0
  }]
}]
```

**Smart parameters for conditional nodes**:
```
// IF node — specify branch
operations: [{ type: "addConnections", connections: [{
  source: "IF", sourceOutput: 0, target: "True Branch", targetInput: 0,
  branch: "true"
}]}]

// Switch — specify case
operations: [{ type: "addConnections", connections: [{
  source: "Switch", sourceOutput: 0, target: "Case Handler", targetInput: 0,
  case: "case1"
}]}]
```

**AI connections** (8 types):
```
operations: [{ type: "addConnections", connections: [{
  source: "OpenAI Chat Model", sourceOutput: 0,
  target: "AI Agent", targetInput: 0,
  connectionType: "ai_languageModel"  // ai_tool, ai_memory, ai_outputParser, etc.
}]}]
```

**Clean stale connections**:
```
operations: [{ type: "cleanStaleConnections" }]
```

**Activate/deactivate**:
```
operations: [{ type: "activateWorkflow" }]
operations: [{ type: "deactivateWorkflow" }]
```

### Workflow Lifecycle
```
Create (n8n_create_workflow)
  → Edit (n8n_update_partial_workflow, iterative, 56s between edits)
  → Validate (validate_workflow)
  → Test (n8n_test_workflow)
  → Activate (activateWorkflow operation)
  → Monitor (n8n_executions)
  → Version (n8n_workflow_versions)
```

---

## Auto-Sanitization System

Runs automatically on **every workflow save** (create or update).

**What it fixes**:
- Binary operators (equals, contains, etc.): Removes incorrect `singleValue`
- Unary operators (isEmpty, isNotEmpty, true, false): Adds `singleValue: true`
- IF v2.2+ / Switch v3.2+: Adds `conditions.options` metadata

**What it cannot fix**:
- Broken connections → Use `cleanStaleConnections`
- Branch count mismatches → Add missing connections or remove extra rules
- Paradoxical corrupt states → May require manual DB intervention

**Key insight**: Don't waste time manually fixing operator structures. Trust auto-sanitization.

---

## Templates and AI Guidance

### search_templates
```
search_templates({ query: "webhook slack notification" })
search_templates({ query: "ai agent chatbot" })
search_templates({ query: "database sync" })
```

### ai_agents_guide
Returns comprehensive guidance for building AI agent workflows:
- 8 AI connection types
- Tool configuration patterns
- Memory options
- Best practices

**Always call this before building AI workflows.**

---

## Tool Usage Patterns (from Telemetry)

| Pattern | Frequency | Avg Time |
|---------|-----------|----------|
| search → get_node (standard) | Very high | 18s |
| get_node → configure → validate | High | 56s between edits |
| validate → fix → validate | 79% lead to loops | 23s think + 58s fix |
| update_partial_workflow | Most used (38,287) | 56s between edits |
| create → edit → validate → activate | Full lifecycle | Minutes |

**Key insight**: Workflow development is iterative. Expect multiple edit-validate cycles. Average 2-3 validation iterations per node configuration.
