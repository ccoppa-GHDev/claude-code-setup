# n8n Node Configuration Reference

Operation-aware configuration guide with dependency handling and top node patterns.

---

## Configuration Philosophy

**Operation-aware**: Properties change based on resource + operation selection. Always configure in order:
1. Resource (e.g., "message")
2. Operation (e.g., "post")
3. Required fields for that operation
4. Optional fields

**Progressive discovery**: Use `get_node` at `standard` detail first (95% success). Only escalate to `full` or `search_properties` if needed.

---

## 8-Step Configuration Workflow

```
1. search_nodes("slack")              → Find node
2. get_node(standard)                 → See operations
3. Select resource + operation        → e.g., message + post
4. Identify required fields           → channel, text
5. Configure required fields          → channel: "#general"
6. Add optional fields                → blocks, attachments
7. validate_node(runtime)             → Check config
8. Fix errors → validate again        → Iterate (2-3 cycles)
```

---

## displayOptions: Why Fields Appear/Disappear

Fields are conditionally shown based on other field values using `displayOptions`:

```json
{
  "name": "text",
  "displayName": "Message Text",
  "type": "string",
  "displayOptions": {
    "show": {
      "resource": ["message"],
      "operation": ["post", "update"]
    }
  }
}
```

This means `text` only appears when `resource=message` AND `operation=post` or `operation=update`.

### Dependency Patterns

**Boolean toggle** — Field shows when toggle is on:
```json
"displayOptions": { "show": { "sendBody": [true] } }
```
→ Body configuration only appears when `sendBody: true`

**Resource/operation cascade** — Most common pattern:
```json
"displayOptions": { "show": { "resource": ["message"], "operation": ["post"] } }
```
→ Slack `channel` field only shows for message/post

**Type-specific fields** — Different config per type:
```json
"displayOptions": { "show": { "authentication": ["oAuth2"] } }
```
→ OAuth fields only show when authentication type is OAuth2

**Method-specific** — HTTP Request method determines fields:
```json
"displayOptions": { "show": { "method": ["POST", "PUT", "PATCH"] } }
```
→ Body options only for methods that have bodies

### Finding Dependencies

Use `search_properties` mode when fields seem missing:
```
get_node({
  nodeType: "nodes-base.httpRequest",
  mode: "search_properties",
  query: "body"
})
```

This reveals which other fields must be set for `body` to become visible.

---

## Top 20 Node Configuration Patterns

### HTTP Request

**GET (fetch data)**:
```javascript
{
  method: "GET",
  url: "https://api.example.com/users",
  authentication: "predefinedCredentialType",
  nodeCredentialType: "httpHeaderAuth",
  sendQuery: true,
  queryParameters: {
    "page": "1",
    "limit": "100"
  },
  sendHeaders: true,
  headerParameters: {
    "Accept": "application/json"
  }
}
```

**POST (send data)**:
```javascript
{
  method: "POST",
  url: "https://api.example.com/users",
  authentication: "predefinedCredentialType",
  sendBody: true,                    // ← REQUIRED for POST!
  bodyParametersJson: JSON.stringify({
    name: "={{ $json.name }}",
    email: "={{ $json.email }}"
  }),
  sendHeaders: true,
  headerParameters: {
    "Content-Type": "application/json"
  }
}
```

**PUT/PATCH (update)**:
```javascript
{
  method: "PATCH",
  url: "https://api.example.com/users/={{ $json.id }}",
  sendBody: true,
  bodyParametersJson: JSON.stringify({ status: "active" })
}
```

**DELETE**:
```javascript
{
  method: "DELETE",
  url: "https://api.example.com/users/={{ $json.id }}"
}
```

### Webhook

**Basic**:
```javascript
{
  path: "my-webhook",
  httpMethod: "POST",
  responseMode: "onReceived",    // Instant 200 OK
  responseData: "allEntries"
}
```

**With custom response**:
```javascript
{
  path: "my-webhook",
  httpMethod: "POST",
  responseMode: "lastNode"       // Use Webhook Response node
}
// + Webhook Response node with statusCode, headers, body
```

### Slack

**Post message**:
```javascript
{
  resource: "message",
  operation: "post",
  channel: "#general",           // Required
  text: "Hello from n8n!"        // Required
}
```

**Update message**:
```javascript
{
  resource: "message",
  operation: "update",
  channel: "#general",
  ts: "={{ $json.ts }}",         // Message timestamp
  text: "Updated message"
}
```

### Gmail

**Send email**:
```javascript
{
  resource: "message",
  operation: "send",
  to: "={{ $json.email }}",
  subject: "Notification",
  message: "Hello {{ $json.name }}"
}
```

### Postgres

**Execute query (parameterized)**:
```javascript
{
  operation: "executeQuery",
  query: "SELECT * FROM users WHERE status = $1 AND created_at > $2 LIMIT $3",
  parameters: ["active", "={{ $json.since }}", "100"]
}
// ⚠️ ALWAYS use parameterized queries to prevent SQL injection
```

**Insert**:
```javascript
{
  operation: "insert",
  table: "users",
  columns: "name, email, created_at",
  returnFields: "id"
}
```

**Update**:
```javascript
{
  operation: "update",
  table: "users",
  updateKey: "id",
  columns: "name, email, updated_at"
}
```

### Set Node

**Fixed values**:
```javascript
{
  mode: "manual",
  duplicateItem: false,
  assignments: {
    assignments: [
      { name: "user_email", value: "={{ $json.body.email }}", type: "string" },
      { name: "timestamp", value: "={{ $now.toISO() }}", type: "string" },
      { name: "source", value: "webhook", type: "string" }
    ]
  }
}
```

### Code Node

**Per-item processing**:
```javascript
{
  mode: "runOnceForEachItem",
  jsCode: "return { json: { name: $input.item.json.name.toUpperCase() } };"
}
```

**All items processing**:
```javascript
{
  mode: "runOnceForAllItems",
  jsCode: "return $input.all().map(i => ({ json: { ...i.json, processed: true } }));"
}
```

### IF Node

**String comparison**:
```javascript
{
  conditions: {
    boolean: [{
      value1: "={{ $json.status }}",
      operation: "equals",
      value2: "active"
    }]
  }
}
```

**Number comparison**:
```javascript
{
  conditions: {
    boolean: [{
      value1: "={{ $json.amount }}",
      operation: "greaterThan",
      value2: "100"
    }]
  }
}
```

**Multiple conditions (AND)**:
```javascript
{
  conditions: {
    boolean: [
      { value1: "={{ $json.status }}", operation: "equals", value2: "active" },
      { value1: "={{ $json.role }}", operation: "equals", value2: "admin" }
    ]
  }
}
```

**Empty check (unary)**:
```javascript
{
  conditions: {
    boolean: [{
      value1: "={{ $json.email }}",
      operation: "isNotEmpty"
      // singleValue: true ← Added automatically by auto-sanitization
    }]
  }
}
```

### Switch Node

**Rules mode**:
```javascript
{
  mode: "rules",
  rules: {
    rules: [
      { output: 0, value1: "={{ $json.type }}", operation: "equals", value2: "bug" },
      { output: 1, value1: "={{ $json.type }}", operation: "equals", value2: "feature" },
      { output: 2, value1: "={{ $json.type }}", operation: "equals", value2: "question" }
    ]
  },
  fallbackOutput: 3    // Unmatched items
}
```

### Schedule Trigger

**Daily at specific time**:
```javascript
{
  rule: {
    interval: [{
      field: "cronExpression",
      expression: "0 9 * * *"        // 9 AM daily
    }]
  },
  timezone: "America/Los_Angeles"     // ← Always specify!
}
```

**Every N minutes**:
```javascript
{
  rule: {
    interval: [{
      field: "minutes",
      minutesInterval: 15
    }]
  }
}
```

### OpenAI Chat Model (AI)

```javascript
{
  model: "gpt-4",
  temperature: 0.7,
  maxTokens: 1000
}
// Connect via ai_languageModel to AI Agent node
```

---

## Common Configuration Gotchas

### 1. POST Without sendBody
```javascript
// ❌ Body silently ignored
{ method: "POST", url: "...", bodyParametersJson: "{...}" }

// ✅ Must enable sendBody
{ method: "POST", url: "...", sendBody: true, bodyParametersJson: "{...}" }
```

### 2. SQL Injection
```javascript
// ❌ Vulnerable
{ query: `SELECT * FROM users WHERE name = '${$json.name}'` }

// ✅ Parameterized
{ query: "SELECT * FROM users WHERE name = $1", parameters: ["={{ $json.name }}"] }
```

### 3. Missing Timezone
```javascript
// ❌ Uses server timezone (unpredictable with DST)
{ rule: { interval: [{ field: "cronExpression", expression: "0 9 * * *" }] } }

// ✅ Explicit timezone
{ ..., timezone: "America/Los_Angeles" }
```

### 4. Fields Not Visible
If a field you expect is missing, check `displayOptions` dependencies:
- Set `sendBody: true` before configuring body fields
- Set correct `method` before seeing method-specific options
- Set `authentication` type before seeing auth fields
- Use `get_node` with `search_properties` mode to discover dependencies

### 5. Case-Sensitive Enum Values
```javascript
// ❌ Wrong case
{ resource: "Message", operation: "Post" }

// ✅ Exact case match
{ resource: "message", operation: "post" }
```
